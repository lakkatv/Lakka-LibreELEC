#!/usr/bin/env python
# -*- coding: utf-8 -*-

# SPDX-License-Identifier: GPL-2.0
# Copyright (C) 2019-present Team LibreELEC (https://libreelec.tv)

from __future__ import print_function
import sys, os, codecs, json, argparse, re

ROOT_PKG = "__root__"

class LibreELEC_Package:
    def __init__(self, name, section):
        self.name = name
        self.section = section
        self.deps = {"bootstrap": [],
                     "init":      [],
                     "host":      [],
                     "target":    []}
        self.wants = []
        self.wantedby = []

    def __repr__(self):
        s = "%-9s: %s" % ("name", self.name)
        s = "%s\n%-9s: %s" % (s, "section", self.section)

        for t in self.deps:
            s = "%s\n%-9s: %s" % (s, t, self.deps[t])

        s = "%s\n%-9s: %s" % (s, "NEEDS", self.wants)
        s = "%s\n%-9s: %s" % (s, "WANTED BY", self.wantedby)

        return s

    def addDependencies(self, target, packages):
        for d in " ".join(packages.split()).split():
            self.deps[target].append(d)
            name = d.split(":")[0]
            if name not in self.wants and name != self.name:
                self.wants.append(name)

    def delDependency(self, target, package):
        if package in self.deps[target]:
            self.deps[target].remove(package)
            name = package.split(":")[0]
            if name in self.wants:
                self.wants.remove(name)

    def addReference(self, package):
        name = package.split(":")[0]
        if name not in self.wantedby:
            self.wantedby.append(name)

    def delReference(self, package):
        name = package.split(":")[0]
        if name in self.wantedby:
            self.wantedby.remove(name)

    def isReferenced(self):
        return False if self.wants == [] else True

    def isWanted(self):
        return False if self.wantedby == [] else True

    def references(self, package):
        return package in self.wants

# Reference material:
# https://www.electricmonk.nl/docs/dependency_resolving_algorithm/dependency_resolving_algorithm.html
class Node:
    def __init__(self, name, target, section):
        self.name = name
        self.target = target
        self.section = section
        self.fqname = "%s:%s" % (name, target)
        self.edges = []

    def appendEdges(self, node):
        # Add the node itself...
        if node not in self.edges:
            self.edges.append(node)
        # as well as its edges
        for e in node.edges:
            if e not in self.edges:
                self.edges.append(e)

    # Return True if the dependencies of the specified node are met by this node
    def satisfies(self, node):
        for e in node.edges:
            if e not in self.edges:
                return False
        return True

    def __repr__(self):
        s = "%-9s: %s" % ("name", self.name)
        s = "%s\n%-9s: %s" % (s, "target", self.target)
        s = "%s\n%-9s: %s" % (s, "fqname", self.fqname)
        s = "%s\n%-9s: %s" % (s, "common", self.commonName())
        s = "%s\n%-9s: %s" % (s, "section", self.section)

        for e in self.edges:
            s = "%s\nEDGE: %s" % (s, e.fqname)

        return s

    def commonName(self):
        return self.name if self.target == "target" else "%s:%s" % (self.name, self.target)

    def addEdge(self, node):
        self.edges.append(node)

def eprint(*args, **kwargs):
        print(*args, file=sys.stderr, **kwargs)

# Read a JSON list of all possible packages from stdin
def loadPackages():
    jdata = json.loads("[%s]" % sys.stdin.read().replace('\n','')[:-1])

    map = {}

    # Load "global" packages first
    for pkg in jdata:
        if pkg["hierarchy"] == "global":
            map[pkg["name"]] = initPackage(pkg)

    # Then the "local" packages, as these will replace any matching "global" packages
    for pkg in jdata:
        if pkg["hierarchy"] == "local":
            map[pkg["name"]] = initPackage(pkg)

    return map

# Create a fully formed LibreELEC_Package object
def initPackage(package):
    pkg = LibreELEC_Package(package["name"], package["section"])

    for target in ["bootstrap", "init", "host", "target"]:
        pkg.addDependencies(target, package[target])

    return pkg

# Split name:target into components
def split_package(name):
    parts = name.split(":")
    pn = parts[0]
    pt = parts[1] if len(parts) != 1 else "target"
    return (pn, pt)

# Return a list of packages of the specified type
def get_packages_by_target(target, list):
    newlist = []

    for p in list:
        (pn, pt) = split_package(p)
        if target in ["target", "init"] and pt in ["target", "init"]:
            newlist.append(p)
        elif target in ["bootstrap", "host"] and pt in ["bootstrap", "host"]:
            newlist.append(p)

    return newlist

# For the specified node iterate over the list of scheduled nodes and return the first
# position where we could possibly build this node (ie. all dependencies satisfied).
def findbuildpos(node, list):

    # Keep a running total of all dependencies as we progress through the list
    alldeps = Node("", "", "")

    candidate = None
    for n in list:
        alldeps.appendEdges(n)
        if alldeps.satisfies(node):
            if len(n.edges) > len(node.edges):
                if candidate == None:
                    candidate = n
                break
            candidate = n

    return list.index(candidate) + 1 if candidate else -1

# Resolve dependencies for a node
def dep_resolve(node, resolved, unresolved, noreorder):
    unresolved.append(node)

    for edge in node.edges:
        if edge not in resolved:
            if edge in unresolved:
                    raise Exception('Circular reference detected: %s -> %s\nRemove %s from %s package.mk::PKG_DEPENDS_%s' % \
                                    (node.fqname, edge.commonName(), edge.commonName(), node.name, node.target.upper()))
            dep_resolve(edge, resolved, unresolved, noreorder)

    if node not in resolved:
        pos = -1 if noreorder else findbuildpos(node, resolved)
        if pos != -1:
            resolved.insert(pos, node)
        else:
            resolved.append(node)

    unresolved.remove(node)

# Return a list of build steps for the trigger packages
def get_build_steps(args, nodes, trigger_pkgs, built_pkgs):
    resolved = []
    unresolved = []

    # When building the image the :target packages must be installed.
    #
    # However, if we are not building the image then only build the packages
    # and don't install them as it's likely we will be building discrete add-ons
    # which are installed outside of the image.
    #
    install = True if "image" in args.build else False

    for pkgname in [x for x in trigger_pkgs if x]:
        if pkgname.find(":") == -1:
            pkgname = "%s:target" % pkgname

        if pkgname in nodes:
            dep_resolve(nodes[pkgname], resolved, unresolved, args.no_reorder)

    # Abort if any references remain unresolved
    if unresolved != []:
        eprint("The following dependencies have not been resolved:")
        for dep in unresolved:
            eprint("  %s" % dep)
        raise("Unresolved references")

    # Output list of resolved dependencies
    for pkg in resolved:
        if pkg.fqname not in built_pkgs:
            built_pkgs.append(pkg.fqname)
            task = "build" if pkg.fqname.endswith(":host") or pkg.fqname.endswith(":init") or not install else "install"
            yield(task, pkg.fqname)

# Reduce the complete list of packages to a map of those packages that will
# be needed for the build.
def processPackages(args, packages, build):
    # Add dummy package to ensure build/install dependencies are not culled
    pkg = {
            "name": ROOT_PKG,
            "section": "virtual",
            "hierarchy": "global",
            "bootstrap": "",
            "init": "",
            "host": " ".join(get_packages_by_target("host", build)),
            "target": " ".join(get_packages_by_target("target", build))
          }

    packages[pkg["name"]] = initPackage(pkg)

    # Resolve reverse references that we can use to ignore unreferenced packages
    for pkgname in packages:
        for opkgname in packages:
            opkg = packages[opkgname]
            if opkg.references(pkgname):
                if pkgname in packages:
                    packages[pkgname].addReference(opkgname)

    # Identify unused packages
    while True:
        changed = False
        for pkgname in packages:
            pkg = packages[pkgname]
            if pkg.isWanted():
                for opkgname in pkg.wantedby:
                    if opkgname != ROOT_PKG:
                        if not packages[opkgname].isWanted():
                            pkg.delReference(opkgname)
                            changed = True
        if not changed:
            break

    # Create a new map of "needed" packages
    needed_map = {}
    for pkgname in packages:
        pkg = packages[pkgname]
        if pkg.isWanted() or pkgname == ROOT_PKG:
            needed_map[pkgname] = pkg

    # Validate package dependency references
    for pkgname in needed_map:
        pkg = needed_map[pkgname]
        for t in pkg.deps:
            for d in pkg.deps[t]:
                if split_package(d)[0] not in needed_map and not args.ignore_invalid:
                    msg = 'Invalid package reference: dependency %s in package %s::PKG_DEPENDS_%s is not valid' % (d, pkgname, t.upper())
                    if args.warn_invalid:
                        eprint("WARNING: %s" % msg)
                    else:
                        raise Exception(msg)

    node_map = {}

    # Convert all packages to target-specific nodes
    for pkgname in needed_map:
        pkg = needed_map[pkgname]
        for target in pkg.deps:
            if pkg.deps[target]:
                node = Node(pkgname, target, pkg.section)
                node_map[node.fqname] = node

    # Ensure all referenced dependencies exist as a basic node
    for pkgname in needed_map:
        pkg = needed_map[pkgname]
        for target in pkg.deps:
            for dep in pkg.deps[target]:
                dfq = dep if dep.find(":") != -1 else "%s:target" % dep
                if dfq not in node_map:
                    (dfq_p, dfq_t) = split_package(dfq)
                    if dfq_p in packages:
                        dpkg = packages[dfq_p]
                        node_map[dfq] = Node(dfq_p, dfq_t, dpkg.section)
                    elif not args.ignore_invalid:
                        raise Exception("Invalid package! Package %s cannot be found for this PROJECT/DEVICE/ARCH" % dfq_p)

    # To each target-specific node, add the corresponding
    # target-specific dependency nodes ("edges")
    for name in node_map:
        node = node_map[name]
        if node.name not in needed_map:
            if args.warn_invalid:
                continue
            else:
                raise Exception("Invalid package! Package %s cannot be found for this PROJECT/DEVICE/ARCH" % node.name)
        for dep in needed_map[node.name].deps[node.target]:
            dfq = dep if dep.find(":") != -1 else "%s:target" % dep
            if dfq in node_map:
                node.addEdge(node_map[dfq])

    return node_map

#---------------------------------------------
parser = argparse.ArgumentParser(description="Generate package dependency list for the requested build/install packages.    \
                                              Package data will be read from stdin in JSON format.", \
                                 formatter_class=lambda prog: argparse.HelpFormatter(prog,max_help_position=25,width=90))

parser.add_argument("-b", "--build", nargs="+", metavar="PACKAGE", required=True, \
                    help="Space-separated list of build trigger packages, either for host or target. Required property - specify at least one package.")

parser.add_argument("--warn-invalid", action="store_true", \
                    help="Warn about invalid/missing dependency packages, perhaps excluded by a PKG_ARCH incompatability. Default is to abort.")

parser.add_argument("--no-reorder", action="store_true", default="True", \
                    help="Do not resequence steps based on dependencies. This is the default.")

parser.add_argument("--reorder", action="store_false", dest="no_reorder", \
                    help="Disable --no-reorder and resequence packages to try and reduce stalls etc.")

parser.add_argument("--show-wants", action="store_true", \
                    help="Output \"wants\" dependencies for each step.")

parser.add_argument("--hide-wants", action="store_false", dest="show_wants", default="True", \
                    help="Disable --show-wants.")

parser.add_argument("--ignore-invalid", action="store_true", \
                    help="Ignore invalid packages.")

args = parser.parse_args()

ALL_PACKAGES = loadPackages()

loaded = len(ALL_PACKAGES)

REQUIRED_PKGS = processPackages(args, ALL_PACKAGES, args.build)

# Output list of packages to build/install
built_pkgs = []
steps = []

for step in get_build_steps(args, REQUIRED_PKGS, args.build, built_pkgs):
    steps.append(step)

eprint("Packages loaded : %d" % loaded)
eprint("Build trigger(s): %d [%s]" % (len(args.build), " ".join(args.build)))
eprint("Package steps   : %d" % len(steps))
eprint("")

# Output build/install steps
if args.show_wants:
    for step in steps:
        wants = []
        node = (REQUIRED_PKGS[step[1]])
        for e in node.edges:
            wants.append(e.fqname)
        print("%-7s %-25s (wants: %s)" % (step[0], step[1].replace(":target",""), ", ".join(wants).replace(":target","")))
else:
    for step in steps:
        print("%-7s %s" % (step[0], step[1].replace(":target","")))
