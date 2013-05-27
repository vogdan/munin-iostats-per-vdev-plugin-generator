#!/bin/bash

#
# generator.sh
#
#       Script used to generate munin plugins from the output of "iostat -xn 1 1" and "zpool iostat"  
# 
# SYNOPSIS
# --------
#       generator_utilization type [symlink_path [clean]]
# 
# PARAMETERS
# ----------
# type - mandatory
#       ACCEPTED VALUES:
#
#          - "utilization" : will use generator_utilization.gen to generate munin plugins that graph the %b ans %w 
#                                                           values from 'iostat -xn 1 1' for all devices of each 
#                                                           vdev found in the pool groups shown by 'zpool iostat'
#
#          - "responsiveness": will use generator_responsiveness.gen to generate munin plugins that graph the asvc_t 
#                                                           value from 'iostat -xn 1 1' for all devices of each 
#                                                           vdev found in the pool groups shown by 'zpool iostat'
#
#          - "bandwith": will use generator_bandwith.gen to generate munin plugins that graph the bandwidth read/write 
#                                                           values from 'zpool iostat -v' for all devices of each 
#                                                           vdev found in the pool groups shown by 'zpool iostat'
#
#          - "operations": will use generator_operations.gen to generate plugins that graph the operations read/write
#                                                           values from 'zpool iostat -v' for all devices of each 
#                                                           vdev found in the pool groups shown by 'zpool iostat'
#
#          - "storage": will use generator_storage.gen to generate plugins that graph the capacity alloc/free values as
#                                                           of 'zpool iostat' for all pool groups
#
# symlink_path - optional
#       Path to create symlinks to generated plugins (to aid in plugin install)     
#
# clean - optional
#       Only works as the second argument and cleans all files and symlink created in a previous run by this script
# 
# EXAMPLES
# -------
#       ./generator.sh utilization
#       
#               -creates plugins (in the current dir) for all zpools found via zpool iostat.
#       
#       ./generator_utilization.sh utilization /opt/munin/plugins
#
#                  -creates plugins and adds symbolic links to these plugins at the specified path
#       
#       ./generator_utilization.sh utilization /opt/munin/plugins clean
#
#                  -deletes all plugins created by this script in the current dir and unlinks symlinks
#
# OUTPUT
# ------
#           
#       
# NOTES
# -----
#       Will not work for pools with no vdevs
#
#
# LICENSE
# -------
#       GPLv2      
#
# AUTHOR
# ------
#       Bogdan Dumitrica (May 2013)
#



MAX_VDEVS=10
ACCEPTED_TYPES=""


#######################################################################
#
# Generate the plugin
#
writePlugin() {

	NAME=$1
    NUMBER=$2 
    DEVS=$3

    if [ "$TYPE" = "storage" ];
    then
        PLUGIN_NAME=${NAME}_$TYPE
    else
        PLUGIN_NAME=${NAME}_vdev-${NUMBER}_$TYPE
    fi    
    echo "$PLUGIN_NAME"

    if [[ -n $LINK_PATH ]]
    then
        if [ -L $LINK_PATH/$PLUGIN_NAME ] 
        then            
            echo "\tUnlinking symlink at $LINK_PATH"
            unlink $LINK_PATH/$PLUGIN_NAME
        fi    
    fi

    if [ -e $PLUGIN_NAME ]
    then
        echo "\tDeleting ${PLUGIN_NAME}..."
        rm -rf $PLUGIN_NAME        
    fi

    if [[ -n $CLEAN ]]
    then
        echo "\tCleaning done."
        continue
    fi
    
    echo "\tCreating plugin file..."

    ./generator_${TYPE}.gen "$PLUGIN_NAME" "$NAME" "$NUMBER" "$DEVS"
    if [ $? != 0 ]
    then 
        exit
    fi

    echo "\tMaking executable..."
    chmod +x $PLUGIN_NAME

    if [[ -n $LINK_PATH ]]
    then
        echo "\tCreating symlink at $LINK_PATH ..."
        ln -s $PWD/$PLUGIN_NAME $LINK_PATH/$PLUGIN_NAME
    fi
} 

if [ $# -gt 0 ]
then
    TYPE=$1
    LINK_PATH=`echo $2 | sed 's:/$::'`
    CLEAN=$3
fi

ARRAY_NAMES=`zpool iostat | awk '{print $1}'`
#ARRAY_NAMES=`cat /home/bogdan/zpool.txt | awk '{print $1}'`

ARRAY_NAMES=`echo $ARRAY_NAMES | sed 's/^capac.*----\ //;s/\ -*$//'`

for ARRAY_NAME in $ARRAY_NAMES
do
    if [ "$TYPE" = "storage" ];
    then
        writePlugin "$ARRAY_NAME"       
    else
	    ARRAY_DETAILS=`zpool iostat -v | awk "/$ARRAY_NAME/, /--+/" | sed '/^[ -]*$/d' | awk '{print $1}'`
#	    ARRAY_DETAILS=`cat /home/bogdan/zpoolverb.txt | awk "/$ARRAY_NAME/, /--+/" | sed '/^[ -]*$/d' | awk '{print $1}'`
	    if [ "$ARRAY_DETAILS" != "" ]
        then
            	NAME=`echo $ARRAY_DETAILS | awk '{print $1}'`
	            VDEVS=`echo $ARRAY_DETAILS | sed "s/$NAME//;s/ mirror /_/g"`
                for (( i=2; i<${MAX_VDEVS}; i++ ));
                do                 
                    VDEV=`echo $VDEVS | cut -d'_' -f${i}`
                    if [ "$VDEV" != "" ] 
                    then
      	    	        writePlugin "$NAME" "$(expr $i - 1)" "$VDEV"
                    else
                        break
                    fi
                done
	    fi
    fi
done
