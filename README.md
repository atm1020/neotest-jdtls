# neotest-jdtls
* This plugin provides a jdtls adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
* Only supports Junit5 tests.

### Installation

```
{
  'atm1020/neotest-jdtls', 
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

### Logging
- logs are written to `neotest-jdtls.log` within the `~/.local/share/nvim/` directory.
- log level can be set with `vim.g.neotest_jdtls_log_level`.



### Acknowledgements
- **[neotest-java](https://github.com/rcasia/neotest-java)**
