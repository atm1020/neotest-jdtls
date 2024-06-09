# neotest-jdtls (Under Development)
* This plugin provides a jdtls adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
    * Currently depends on the nvim-java-core and nvim-java-test projects.
    * Integration with [nvim-java](https://github.com/nvim-java/nvim-java) project is tested.

### Limitations
- No support for multi-module projects.
- Only supports running all tests in a file or running a single test method (no directory support).
- Compiler errors are not recognized as errors (the tests appear to pass).

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
