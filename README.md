# neotest-jdtls (Under Development)
* This plugin provides a jdtls adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
    * Depends on the nvim-java-core and nvim-java-test projects.

### Installation

```
{
  'atm1020/neotest-jdtls', 
    dependencies = {
     nvim-java/nvim-java-core,
     nvim-java/nvim-java-test,
  }
}
```


### Setup

```lua
require("neotest").setup {
 adapters = {
   require('neotest-jdtls')
 },
}
```

### Acknowledgements
- **[neotest-java](https://github.com/rcasia/neotest-java)**
