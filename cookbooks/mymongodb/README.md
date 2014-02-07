mymongodb Cookbook
==================
A sample mongodb deployment cookbook.

Requirements
------------

#### packages
- `mongodb` - mymongodb installs the mongodb software.
- `knife-google` - mymongodb needs the knife-google gem.
- `gceutil` - mymongodb depends on gceutil cookbook for persistent disk
              management.
- `mongodb` - mymongodb depends on the mongodb cookbook for mongodb management.

Attributes
----------


Usage
-----
#### mymongodb::default
Creates a persistent disk, attach the disk, and then install and run mongodb
using the disk as storage.

e.g.
Just include `mymongodb` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[mymongodb]"
  ]
}
```

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
Authors: ntang@google.com
