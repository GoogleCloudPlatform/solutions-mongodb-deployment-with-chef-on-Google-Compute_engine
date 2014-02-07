gceutil Cookbook
============
A sample cookbook to automate Google Compute Engine instance configuration.
Right now, the cookbook only support Persistent Disk configuration.

Requirements
------------
The cookbook depends on the ruby gem "knife-google".

Attributes
----------

e.g.
#### gceutil::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['gceutil']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### gceutil::default
Demonstrates you could create, attach a disk to an instance, detach the disk,
and delete the disk.
e.g.
Just include `gceutil` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[gceutil]"
  ]
}

#### gceutil::create_disk
Creates a new persistent disk.

#### gceutil::attach_disk
Attaches a persistent disk to an instance.

#### gceutil::detach_disk
Detaches a persistent disk from an instance.

#### gceutil::delete_disk
Deletes an existing persistent disk.

Contributing
------------

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write you change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: ntang@google.com.
