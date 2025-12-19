# neotest-jdtls
* This plugin provides a jdtls adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.
* Supports Junit5, Junit4 tests.

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

#### Lazy.nvim 
```lua
return {
    {
        "atm1020/neotest-jdtls",
        dependencies = {
            "nvim-neotest/neotest",
        },
    },
    {
        "nvim-neotest/neotest",
        opts = { adapters = { "neotest-jdtls" } },
    },
}
```

### Check `neotest-jdtls` is ready to use
- `checkhealth neotest-jdtls`

### Commands
- `NeotestJdtlsClearProjectCache` : Clear jdtls project cache.

### Logging
- logs are written to `neotest-jdtls.log` within the `~/.local/share/nvim/` directory.
- log level can be set with `vim.g.neotest_jdtls_log_level`.



### Acknowledgements
- **[neotest-java](https://github.com/rcasia/neotest-java)**
