# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Define the "pdisk" defintion for persistent disk management.
#
# The definition support disk operations for create, delete, attach, detach.
#
# Args:
# - action: the allowed action string.
# - zone: the zone name.
# - size: the size of the disk in GB
# - mode: the disk mode.
# - instance: the VM instance name.
# - device: the disk device name.
# - mountdir: the disk mounting directory.
# - safe_format: true if you want to safe format the disk;
#                otherwise, false. (safe to always true).
#
define :pdisk,
  :action => [:create, :delete, :attach, :detach, :mount, :umount, :nothing],
  :zone => nil, :size => 10,
  :mode => "READ_WRITE", :instance => nil, :device => nil,
  :mountdir => nil, :safe_format => true do
  disk_name = params[:name]
  disk_action = params[:action]
  disk_size = params[:size]
  disk_zone = params[:zone]
  instance_name = params[:instance]
  if instance_name.nil? || instance_name.empty?
    instance_name = Chef::Config[:node_name]
  end
  device_name = params[:device]
  device_mode = params[:mode]
  mount_dir = params[:mountdir]
    safe_format = params[:safe_format]

  if disk_action == "create"
    ruby_block "create_disk" do
      block do
        pd = GooglePersistenceDisk.new()
        pd.create(disk_name, disk_size, disk_zone)
      end
    end
  else
    if disk_action == "delete"
      ruby_block "delete_disk" do
        block do
          pd = GooglePersistenceDisk.new()
          pd.delete(disk_name, disk_zone)
        end
      end
    else
      if disk_action == "attach"
        ruby_block "attach_disk" do
          block do
            pd = GooglePersistenceDisk.new()
            pd.attach(instance_name, disk_name, device_name, device_mode, disk_zone)
          end
        end
      else
        if disk_action == "detach"
          ruby_block "detach_disk" do
            block do
              pd = GooglePersistenceDisk.new()
              pd.detach(instance_name, device_name, disk_zone)
            end
          end
        else
          if disk_action == "mount"
            directory mount_dir do
              action :create
            end

            # actually safe_format_and_mount could not reformat a disk.
            # ignore this use case for now.
            if safe_format
              execute "mount the persistent disk" do
                command <<-EOH
                  if mount | grep #{mount_dir}; then
                    echo "WARNING: The directory is already mounted (NOP)"
                  else
                    sudo /usr/share/google/safe_format_and_mount -m "mkfs.ext4 -F" \
                      /dev/disk/by-id/google-#{device_name} #{mount_dir}
                  fi
                EOH
                only_if {::File.exists?(mount_dir)}
              end
            else
              execute "mount the persistent disk" do
                command <<-EOH
                  if mount | grep #{mount_dir}; then
                    echo "WARNING: The directory is already mounted (NOP)"
                  else
                    sudo mount \
                      /dev/disk/by-id/google-#{device_name} #{mount_dir}
                  fi
                EOH
                only_if {::File.exists?(mount_dir)}
              end
            end
          else
            if disk_action == "umount"
              execute "umount the persistent disk" do
                command <<-EOH
                  if mount | grep #{mount_dir}; then
                     sudo umount #{mount_dir}
                  else
                    echo "WARNING: The directory is not mounted (NOP)"
                  fi
                EOH
                only_if {::File.exists?(mount_dir)}
              end
            end
          end
        end
      end
    end
  end
end
