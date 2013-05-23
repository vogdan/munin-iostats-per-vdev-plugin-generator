munin-iostats-per-vdev-plugin-generator
=======================================

Shell script to generate munin plugins that show by ZFS zpool vdevs the disk activity
in terms of latency, throughput, %b, %w, etc. Basically, the output from
iostat -xn 1 1 and zpool iostat -v but arranged in groupings of vdevs.

For each vdev we'll have 4 plugins showing:  
  - operations (read/writes) columns from zpool iostat -v
  - bandwidth (read/write) columns from zpool iostat -v
  - utilization (busy/wait - %w and %b) columns from iostat -xn 1 1 
  - responsiveness (asvc_t) column form iostat -xn 1 1.
 
 
#
# generator.sh
#
       Script used to generate munin plugins from the output of "iostat -xn 1 1" and "zpool iostat"  
 
  SYNOPSIS

              generator type [symlink_path [clean]]
 
  PARAMETERS


    - type - mandatory - accepdet values: "utilization", "responsiveness", "bandwidth" or "operations" 

           - utilization : will use generator_utilization.gen to generate munin plugins that graph the %b ans %w 
                                                               values as of 'iostat -xn 1 1' for all devices of each 
                                                               vdev found in the pool groups shown by 'zpool iostat'

           - responsiveness: will use generator_responsiveness.gen to generate munin plugins that graph the asvc_t 
                                                               value as of 'iostat -xn 1 1' for all devices of each 
                                                               vdev found in the pool groups shown by 'zpool iostat'

           - bandwith: will use generator_bandwith.gen to generate munin plugins that graph the bandwidth read/write 
                                                               values as of 'zpool iostat -v' for all devices of each 
                                                               vdev found in the pool groups shown by 'zpool iostat'

           - operations: will use generator_operations.gen to generate munin plugins that graph the operations read/write
                                                               values as of 'zpool iostat -v' for all devices of each 
                                                               vdev found in the pool groups shown by 'zpool iostat'

    - symlink_path - optional - Path to create symlinks for generated plugins (to aid in plugin install)     

    - clean - optional - Only works as the third argument and cleans all files and symlink created in a previous run by this script
 
  
  EXAMPLES
  
       - Create plugins (in the current dir) for each vdev found via zpool iostat:
             
              ./generator.sh utilization

       - Create plugins and adds symbolic links to these plugins at the specified path
              
              ./generator_utilization.sh utilization /opt/munin/plugins
                  
       - Delete all plugins created by this script in the current dir and unlinks symlinks 
       
              ./generator_utilization.sh utilization /opt/munin/plugins clean
                  
  
  NOTES
 
       Will not work for pools with no vdevs


#  LICENSE
 
          GPLv2
