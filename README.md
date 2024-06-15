# neotest-jdtls (Under Development)
* This plugin provides a jdtls adapter for the [Neotest](https://github.com/rcarriga/neotest) framework.


### Setup

```lua
require("neotest").setup {
 adapters = {
   require('neotest-jdtls')
 },
}
```

#### with debug log
```lua
require('neotest').setup {
 log_level = vim.log.levels.DEBUG,
 adapters = {
  require 'neotest-jdtls',
 },
}
```

### Acknowledgements
- **[neotest-java](https://github.com/rcasia/neotest-java)**
- **[vscode-java-test](https://github.com/microsoft/vscode-java-test)**
