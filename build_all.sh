#!/bin/bash
#
# Lakka build script
#
# This script builds images for all supported platforms/target devices listed in
# the 'targets' variable.
#
# By default (./build_all.sh) it starts in dashboard mode, showing a dashboard
# with the current status of the build job and not bailing out after unsuccessful
# build job (tries to build all targets in one run and then show failed targets
# at the end).
#
# To run in log mode:
# $ DASHBOARD_MODE=off ./build_all.sh
# Or instead of 'off' you can use any other value, e. g. 'foo', except 'yes'
#
# To bail out after first failure:
# $ BAILOUT_FAILED=yes ./build_all.sh
# or instead of 'yes' you can use any other value, e. g. 'bar', except 'no'

# by default start in dashboard mode
[ -z "${DASHBOARD_MODE}" ] && DASHBOARD_MODE="yes"

# by default do not bail out after failed build
[ -z "${BAILOUT_FAILED}" ] && BAILOUT_FAILED="no"

# by default do not use version in build folder
[ -z "${IGNORE_VERSION}" ] && iv="1" || iv="${IGNORE_VERSION}"

# by default reload dashboard / status file every 0.5 seconds
[ -z "${REFRESH_RATE}" ] && rr="0.5s" || rr="${REFRESH_RATE}"

# number of buildthreads = two times number of cpu threads, unless specified otherwise
tc=""
if [ -z "${THREADCOUNT}" ]
then
	if [ -n "$(which nproc)" ]
	then
		tc="THREADCOUNT=$(($(nproc)*2))"
	fi
else
	tc="THREADCOUNT=${THREADCOUNT}"
fi

# set / unset verbose mode for some commands
[ "${DASHBOARD_MODE}" = "yes" ] && v="" || v="-v"

# remove any existing images / release files
rm -rf target/

# list of targets/platforms in structure PROJECT|DEVICE|ARCH|make_rule

targets="\
	Allwinner|A64|arm|image \
	Allwinner|H3|arm|image \
	Allwinner|H6|arm|image \
	Amlogic|AMLG12|arm|image \
	Amlogic|AMLGX|arm|image \
	Generic||x86_64|image \
	Generic||i386|image \
	Rockchip|MiQi|arm|image \
	Rockchip|RK3328|arm|image \
	Rockchip|RK3399|arm|image \
	Rockchip|TinkerBoard|arm|image \
	RPi|Gamegirl|arm|image \
	RPi|RPi|arm|noobs \
	RPi|RPi2|arm|noobs \
	RPi|RPi4|arm|noobs \
	Qualcomm|Dragonboard|arm|image \
	"

# set the number of total build jobs and initialize counter for current build job
total=$(echo ${targets} | wc -w)
declare -i current=0

# initialize variables for list and count of failed builds and count of good jobs
failed_targets=""
declare -i failed_jobs=0
declare -i good_jobs=0

for target in ${targets}
do
	current+=1

	distro="Lakka"
	IFS='|' read -r -a build  <<< "${target}"
	project=${build[0]}
	device=${build[1]}
	arch=${build[2]}
	out=${build[3]}
	target_name=${device:-$project}.${arch}

	# initialize return value of the non-dashboard job
	non_db_ret=0

	# initialize result variable for dashboard job
	failed_dashboard=0

	# set status file
	statusfile="build.${distro}-${target_name}*/.threads/status"

	if [ "${DASHBOARD_MODE}" != "yes" ]
	then
		# show logs during build (non-dashboard build)
		echo "Starting build of ${target_name}"
		make ${out} PROJECT=${project} DEVICE=${device} ARCH=${arch} IGNORE_VERSION=${iv} ${tc}
		non_db_ret=${?}
		if [ ${non_db_ret} -gt 0 -a "${BAILOUT_FAILED}" != "no" ]
		then
			exit ${non_db_ret}
		fi
	else
		# remove the old dashboard, so we don't show old/stale dashboard
		rm -f ${statusfile}
		# start the build process in background
		make ${out} PROJECT=${project} DEVICE=${device} ARCH=${arch} IGNORE_VERSION=${iv} ${tc} &>/dev/null &
		# store the pid
		pid=${!}
		finished=0

		while [ ${finished} -eq 0 ]
		do
			# check if the build process is still running
			ps -q ${pid} &>/dev/null
			ret=${?}
			s_failed="s"
			[ ${failed_jobs} -eq 1 ] && s_failed=""
			s_good="s"
			[ ${good_jobs} -eq 1 ] && s_good=""
			statusline="Build job ${current}/${total}, so far ${good_jobs} successful build${s_good}, ${failed_jobs} failed build${s_failed}"
			if [ ${ret} -eq 0 ]
			then
				# build process is still running, show the dashboard
				if [ -f ${statusfile} ]
				then
					cat ${statusfile}
					if [ $(cat ${statusfile} | wc -l) -gt 2 ]
					then
						echo ""
						echo "${statusline}"
					fi
					sleep ${rr}
				fi
			else
				# build process is not running anymore
				finished=1
				if [ -f ${statusfile} ]
				then
					# show the dashboard
					cat ${statusfile}
					echo ""
					echo "${statusline}"
					# check if there are any failed jobs in the dashboard
					failed_count=$(cat ${statusfile} | grep "^\[" | cut -d' ' -f 2 | grep FAILED | wc -l)
					if [ ${failed_count} -gt 0 ]
					then
						failed_dashboard=1
						if [ "${BAILOUT_FAILED}" != "no" ]
						then
							echo "Build of some package(s) failed:"
							echo ""
							echo "Job id | Package name"
							echo "------.+------------------"
							cat ${statusfile} | grep "FAILED" | sed -e "s/^\[/ /" | sed -e "s/\]\ /  /" | sed -e "s/\// /" | cut -d' ' -f 3,8 | sed -e "s/\ /   | /" | sed -e "s/^/ /"
							echo ""
							echo "Check the logs in build.${distro}.${target_name}*/.threads/logs/<job_id>/"
							exit ${failed_count}
						fi
					fi
				else
					# no dashboard and build process finished - we did not build anything
					failed_dashboard=1
					if [ "${BAILOUT_FAILED}" != "no" ]
					then
						echo "Build job for ${target_name} was probably not started (no dashboard file found)."
						echo "Try running the build manually:"
						echo "PROJECT=${project} DEVICE=${device} ARCH=${arch} IGNORE_VERSION=${iv} make ${out}"
						exit 127
					fi
				fi
			fi
		done
	fi

	if [ ${non_db_ret} -gt 0 -o ${failed_dashboard} -eq 1 ]
	then
		# record the failed build
		failed_jobs+=1
		failed_packages=""
		list=$(cat ${statusfile} | grep "FAILED" | cut -d' ' -f 5)
		for pkg in ${list}
		do
			failed_packages+="${pkg} "
		done
		failed_targets+="${target_name} - ${failed_packages}\n"
	else
		# store the release files in platform/target folder
		good_jobs+=1
		cd target
		mkdir -p ${target_name}
		# add md5 checksums to system and kernel files
		[ "${DASHBOARD_MODE}" = "yes" ] && echo -n "Creating md5 checksums for kernel and system..."
		for file in Lakka-${target_name}-*.{kernel,system}
		do
			[ -f "${file}" ] && md5sum ${file} > ${file}.md5
		done
		[ "${DASHBOARD_MODE}" = "yes" ] && echo "done!"

		# move release files to the folder
		[ "${DASHBOARD_MODE}" = "yes" ] && echo -n "Moving release files (.img.gz, .kernel, .system, -noobs.tar) to subfolder..."
		for file in Lakka-${target_name}-*{.img.gz,-noobs.tar,.kernel,.system}*
		do
			[ -f "${file}" ] && mv ${v} ${file} ${target_name}/
		done
		[ "${DASHBOARD_MODE}" = "yes" ] && echo "done!"
		# remove files we do not use
		[ "${DASHBOARD_MODE}" = "yes" ] && echo -n "Removing unused files (.tar, .ova)..."
		rm -f ${v} Lakka-${target_name}-*.{tar,ova}*
		[ "${DASHBOARD_MODE}" = "yes" ] && echo "done!"
		cd ..
	fi
done

if [ $failed_jobs -gt 0 ]
then
	echo -e "\nFailed ${failed_jobs} build(s):\n${failed_targets}:-(" >&2
else
	echo -e "\nAll successful!\n:-)"
fi

exit $failed_jobs
