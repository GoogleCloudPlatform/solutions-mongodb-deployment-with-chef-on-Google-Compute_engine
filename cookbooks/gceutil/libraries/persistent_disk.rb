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

# A Wrapper class for persistent disk management.
#
# The class provides persistent disk management and hiding the REST API details.
#
class GooglePersistenceDisk

  # Gets the ServiceClient object.
  #
  def client
    @client ||= begin
      ServiceClient.new()
      end
  end

  # Checks to ensure the zone exists.
  #
  # Checks to ensure the zone exists. Otherwise, terminates the execution.
  #
  # Args:
  # - disk_zone: the zone for the disk.
  #
  def zone_check(disk_zone)
    begin
      zone = client.zones.get(disk_zone)
      return zone
    rescue Google::Compute::ResourceNotFound
      Chef::Application.fatal!("Zone '#{disk_zone}' not found")
    end
  end

  # Checks if a disk exists.
  #
  # Checks if a disk exists.
  #
  # Args:
  # - disk_name: the name of the disk.
  # - disk_zone: the zone of the disk.
  #
  # Returns:
  # - True if the disk exist; False otherwise.
  #
  def has_disk?(disk_name, disk_zone)
    zone_check(disk_zone)
    disk = get(disk_name, disk_zone)
    return !disk.nil?
  end

  # Gets a disk.
  #
  # Gets a disk.
  #
  # Args:
  # - disk_name: the name of the disk.
  # - disk_zone: the zone of the disk.
  #
  # Returns:
  # - the disk object or nil if disk does not exist.
  #
  def get(disk_name, disk_zone)
    zone_check(disk_zone)
    begin
      disk = client.disks.get(:name=>disk_name, :zone=>disk_zone)
      return disk
    rescue Google::Compute::ResourceNotFound
      return nil
    end
  end

  # Creates a new persistent disk.
  #
  # Creates a new persistent disk. This is an asynchronous operation.
  #
  # Args:
  # - disk_name: the name of the disk.
  # - disk_size: the disk size in GB.
  # - disk_zone: the zone name of the disk.
  #
  # Returns:
  # - A zone operation.
  #
  def create(disk_name, disk_size, disk_zone)
    if disk_name.nil? || disk_name.empty?
      Chef::Application.fatal!("disk_name is not provided")
    end
    if disk_zone.nil? || disk_zone.empty?
      Chef::Application.fatal!("disk_zone is not provided")
    end

    if has_disk?(disk_name, disk_zone)
      Chef::Log.warn("Disk already exists (NOP): #{disk_name}")
    else
      Chef::Log.info("Try to create new disk")
      disk_operation = client.disks.create(:name => disk_name, :sizeGb=>disk_size, :zone=>disk_zone)
      Chef::Log.info("New disk creation issued: #{disk_operation}")
      disk_operation = client.waitOperationToFinish(disk_operation, disk_zone)
      if ("DONE".casecmp(disk_operation.status)== 0)
        Chef::Log.info("New disk created: #{disk_operation.status}")
      else
        Chef::Application.fatal!("failed to create disk")
      end
      return disk_operation;
    end
  end

  # Deletes a persistent disk.
  #
  # Deletes a persistent disk. This is an asynchronous operation.
  #
  # Args:
  # - disk_name: the name of the disk.
  # - disk_zone: the zone name of the disk.
  #
  # Returns:
  # - A zone operation.
  #
  def delete(disk_name, disk_zone)
    if has_disk?(disk_name, disk_zone)
      disk_operation = client.disks.delete(:zone=>disk_zone, :disk=>disk_name)
      disk_operation = client.waitOperationToFinish(disk_operation, disk_zone)
      if ("DONE".casecmp(disk_operation.status)== 0)
        Chef::Log.info("Disk delete: #{disk_operation.status}")
      else
        Chef::Application.fatal!("failed to deleted disk")
      end
    else
      Chef::Log.warn("Disk does not exist (NOP): #{disk_name}")
    end
  end

  # Attaches a persistent disk to an instance.
  #
  # Attaches a persistent disk to an instance. This is an asynchronous
  # operation.
  #
  # Args:
  # - instance_name: the instance name.
  # - disk_name: the name of the disk.
  # - device_name: the device name.
  # - mode: the disk mode "READ_WRITE" vs "READ_ONLY".
  # - disk_zone: the zone name of the disk.
  #
  # Returns:
  # - A zone operation.
  #
  def attach(instance_name, disk_name, device_name, mode, disk_zone)
    Chef::Log.info("Attach disk #{disk_name} on #{instance_name}")
    if disk_name.nil? || disk_name.empty?
      Chef::Application.fatal!("disk_name is not provided")
    end
    if disk_zone.nil? || disk_zone.empty?
      Chef::Application.fatal!("disk_zone is not provided")
    end

    zone = zone_check(disk_zone)
    disk = self.get(disk_name, disk_zone)
    instance = client.instances.get(:name=>instance_name, :zone=>zone.name)

    if disk.nil?
      Chef::Application.fatal!("Could not find the disk")
    end
    if instance.nil?
      Chef::Application.fatal!("Could not find the instance")
    end

    if device_name.nil?
      device_name = disk_name
    end
    disk_operation =client.attachDisk(instance, disk, device_name, mode, zone)
    disk_operation = client.waitOperationToFinish(disk_operation, disk_zone)
    if ("DONE".casecmp(disk_operation.status)== 0)
      Chef::Log.info("Disk attaching: #{disk_operation.status}")
    else
      Chef::Application.fatal!("failed to attach the disk")
    end
  end

  # Detaches a persistent disk from an instance.
  #
  # Detaches a persistent disk from an instance. This is an asynchronous
  # operation.
  #
  # Args:
  # - instance_name: the instance name.
  # - device_name: the device name.
  # - disk_zone: the zone name of the disk.
  #
  # Returns:
  # - A zone operation.
  #
  def detach(instance_name, device_name, disk_zone)
    Chef::Log.info("Detach disk device #{device_name} on #{instance_name}")
    zone = zone_check(disk_zone)
    instance = client.instances.get(:name=>instance_name, :zone=>zone.name)
    if instance.nil?
      Chef::Application.fatal!("Could not find the instance")
    end

    disk_operation =client.detachDisk(instance, device_name, zone)
    disk_operation = client.waitOperationToFinish(disk_operation, disk_zone)
    if ("DONE".casecmp(disk_operation.status)== 0)
      Chef::Log.info("Disk detach: #{disk_operation.status}")
    else
      Chef::Application.fatal!("failed to detach the disk")
    end
  end
end
