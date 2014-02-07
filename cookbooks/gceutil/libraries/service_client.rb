#
# Copyright (c) 2012 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.
#

# A service client wrapping around the Google Compute Engine REST APIs.
#
# The class provides the high level methods to retrieve the resource collections
# like projects, zones, disks, instances, and etc.
#

class ServiceClient

  # Accessor for the dispatcher object.
  attr_reader :dispatcher

  # Fetches the Compute Engine instance metadata.
  #
  # Args:
  # - url: the metadata url string.
  #
  def self.fetch_metadata(url)
    conn = Faraday.new
    response = conn.get do |req|
      req.url url
      req.headers['X-Google-Metadata-Request'] = 'True'
    end
    return response.body
  end

  # Inits ServiceClient with project id and access token.
  #
  # If the project id is not passed, retrieve the project id from the
  # instance meta data.
  #
  # Args:
  # - project: the numberic project id.
  # - access_token: the OAUTH2 access token string.
  def initialize(project=nil, access_token=nil)
    api_client = Google::APIClient.new(
      :application_name=>'google-compute-ruby-client')
    api_client.auto_refresh_token = false

    if project.nil?
      @project = ServiceClient.fetch_metadata(
          'http://metadata/computeMetadata/v1/project/numeric-project-id')
      Chef::Log.info("Got project id #{@project}")
    end
    api_client.authorization = ServiceClient.setup_authorization(access_token)
    @dispatcher = ServiceClient::APIDispatcher.new(:project=>@project,
      :api_client=>api_client)
  end

  # A help method to set up the REST API authorization object.
  #
  # If the access token is not passed in, retrieve the access token from the,
  # instance meta data.
  #
  # Args:
  # - access_token: An optional OAUTH2 access token string.
  #
  # Returns:
  # - An Signet OAuth2 authorization object.
  #
  def self.setup_authorization(access_token)
    authorization = Signet::OAuth2::Client.new()
    if access_token.nil?
      token_str = ServiceClient.fetch_metadata(
          'http://metadata/computeMetadata/v1' +
          '/instance/service-accounts/default/token')
      token = MultiJson.load(token_str)
      Chef::Log.info("Got token #{token}")
      access_token = token['access_token']
      Chef::Log.info("Got access token #{access_token}")
    end
    scope  = ['https://www.googleapis.com/auth/compute',
        'https://www.googleapis.com/auth/userinfo.email']

    authorization.scope = scope
    authorization.update_token!(:access_token => access_token)
    return authorization
  end

  # Creates a project collection object.
  #
  # Retruns:
  # - A ResourceCollection object.
  #
  def projects
    Google::Compute::ResourceCollection.new(
      :resource_class => Google::Compute::Project, :dispatcher => @dispatcher)
  end

  # Creates a project collection object.
  #
  # Retruns:
  # - A ResourceCollection object.
  #
  def disks
    Google::Compute::CreatableResourceCollection.new(
      :resource_class => Google::Compute::Disk,  :dispatcher=>@dispatcher)
  end

  # Creates an image collection object.
  #
  # Retruns:
  # - A ResourceCollection object.
  #
  def firewalls
    Google::Compute::CreatableResourceCollection.new(
      :resource_class => Google::Compute::Firewall, :dispatcher => @dispatcher)
  end

  # Creates a project collection object.
  #
  # Retruns:
  # - A CreatableResourceCollection object.
  #
  def images
    Google::Compute::CreatableResourceCollection.new(
      :resource_class => Google::Compute::Image, :dispatcher => @dispatcher)
  end

  # Creates an instance collection object.
  #
  # Retruns:
  # - A CreatableResourceCollection object.
  #
  def instances
    Google::Compute::CreatableResourceCollection.new(
      :resource_class => Google::Compute::Server, :dispatcher=>@dispatcher)
  end

  # Creates a project collection object.
  #
  # Retruns:
  # - A ResourceCollection object.
  #
  def kernels
    Google::Compute::ListableResourceCollection.new(
      :resource_class => Google::Compute::Kernel,:dispatcher=>@dispatcher)
  end

  # Creates a machine type collection object.
  #
  # Retruns:
  # - A ListableResourceCollection object.
  #
  def machine_types
    Google::Compute::ListableResourceCollection.new(
      :resource_class => Google::Compute::MachineType,:dispatcher=>@dispatcher)
  end

  # Creates a network collection object.
  #
  # Retruns:
  # - A CreatableResourceCollection object.
  #
  def networks
    Google::Compute::CreatableResourceCollection.new(
      :resource_class => Google::Compute::Network, :dispatcher=>@dispatcher)
  end

  # Creates a global opeartion collection object.
  #
  # Retruns:
  # - A DeletableResourceCollection object.
  #
  def globalOperations
    Google::Compute::DeletableResourceCollection.new(
      :resource_class => Google::Compute::GlobalOperation,
        :dispatcher=>@dispatcher)
  end

  # Creates a zone operation collection object.
  #
  # Retruns:
  # - A DeletableResourceCollection object.
  #
  def zoneOperations
    Google::Compute::DeletableResourceCollection.new(
      :resource_class => Google::Compute::ZoneOperation,
        :dispatcher=>@dispatcher)
  end

  # Creates a zone collection object.
  #
  # Retruns:
  # - A ListableResourceCollection object.
  #
  def zones
    Google::Compute::ListableResourceCollection.new(
      :resource_class => Google::Compute::Zone, :dispatcher=>@dispatcher)
  end

  # Creates a project collection object.
  #
  # Retruns:
  # - A ResourceCollection object.
  #
  def snapshots
    Google::Compute::CreatableResourceCollection.new(
      :resource_class => Google::Compute::Snapshot, :dispatcher=>@dispatcher)
  end

  # Waits until an operation finishes or time out.
  #
  # Wait until an operation finishes by checking the status and progress
  # at intervals. The wait will expire after a specified period of time. Right
  # now, the method only supports zone operation.
  #
  # Args:
  # - operation: the operation object.
  # - zone: the zone name for a zone operations.
  # - timeout_secs: the time out in seconds
  # - check_interval_secs: the status check interval in seconds.
  #
  # Retruns:
  # - The operation object with the latest state and progress.
  #
  def waitOperationToFinish(operation, zone,
    timeout_secs=60, check_interval_secs=2)
    if operation.nil?
      return
    end

    status = Timeout::timeout(timeout_secs) do
      Chef::Log.info(
        "Operation progress (enter): " +
          "#{operation.progress}% #{operation.status}")
      until  operation.progress==100 && operation.status == "DONE"
        sleep check_interval_secs
        data = @dispatcher.dispatch(:api_method=>operation.api_resource.get,
        :parameters=>{:zone=>zone, :operation=>operation.name})
        operation = operation.class.new(data.merge(:dispatcher=>@dispatcher))
        Chef::Log.info("Operation progress (wait): " +
          "#{operation.progress}% #{operation.status}")
      end
    end

    Chef::Log.info(
      "Operation progress (finish): #{operation.progress}% #{operation.status}")
    return operation
  end

  # Attaches a disk to a VM instance.
  #
  # Attaches a disk to a VM instance. Currently, we only support persistent
  # disk attachement. The operation is asynchronous.
  #
  # Args:
  # - instance: the VM instance object.
  # - disk: the disk object.
  # - device_name: the device name for disk.
  # - zone: the zone for the disk and instance.
  #
  # Returns:
  # - A zone operation object.
  #
  def attachDisk(instance, disk, device_name, mode, zone)
    disk_obj = {
      :source => disk.self_link,
      :boot=>false,
      :type=>"PERSISTENT",
      :mode=>mode,
      :deviceName=>device_name
    }
    data = @dispatcher.dispatch(
      :api_method => instance.api_resource.attach_disk,
      :parameters=>{ :project =>@project,
        :zone=>zone.name,
        :instance => instance.name
      },
      :body_object=>disk_obj)
    Google::Compute::ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher))
  end

  # Detaches a disk from a VM instance.
  #
  # Detaches a disk from a VM instance. Currently, we only support persistent
  # disk detachement. The operation is asynchronous.
  #
  # Args:
  # - instance: the VM instance object.
  # - device_name: the device name for disk.
  # - zone: the zone for the disk and instance.
  #
  # Returns:
  # - A zone operation object.
  #
  def detachDisk(instance, device_name, zone)
    disk_obj = {
      :deviceName=>device_name
    }
    data = @dispatcher.dispatch(
      :api_method => instance.api_resource.detach_disk,
      :parameters=>{ :project =>@project,
        :zone=>zone.name,
        :instance => instance.name,
        :deviceName=>device_name
      },
      :body_object=>nil)
    Google::Compute::ZoneOperation.new(data.merge!(:dispatcher=>@dispatcher))
  end

  # An internal Dispatcher object to use Compute Engine REST APIs.
  #
  class APIDispatcher

    attr_reader :project, :api_client

    # Inits an APIDispatcher object.
    def initialize(opts)
      @project= opts[:project]
      @api_client = opts[:api_client]
    end

    # Gets the compute API.
    #
    def compute
      @compute ||= @api_client.discovered_api('compute','v1beta15')
    end

    # Executes an API request.
    #
    def dispatch(opts)
      Chef::Log.info("Dispatch a command: #{opts}")
      begin
        unless opts[:parameters].has_key?(:project)
          opts[:parameters].merge!( :project => @project )
        end
        result = @api_client.execute(:api_method=>opts[:api_method],
        :parameters=>opts[:parameters],
        :body_object => opts[:body_object]
        )
        unless result.success?
          response = MultiJson.load(result.response.body)
          error_code = response["error"]["code"]
          if error_code == 404
            raise Google::Compute::ResourceNotFound, result.response.body
          elsif error_code == 400
            raise Google::Compute::BadRequest, result.response.body
          else
            raise Google::Compute::BadRequest, result.response.body
          end
        end
        return MultiJson.load(result.response.body) unless result.response.body.nil?
      rescue ArgumentError => e
        Chef::Log.info("Got exception #{e}")

        raise Google::Compute::ParameterValidation, e.message
      end
    end
  end
end
