# New-SecurePassword.ps1
This generates a mangled Diceware Passphrase for use as a password.

## Usage:
You must specify the path to the wordlist and how many words you want in your passphrase.

You must specify a minimum of 6 words to get a cracking resistant passphrase.

PS> .\New-SecurePassword.ps1 -EFFWordlist \<Path to EFF Wordlist\> -NumWords \<num\>

## Options:

#### -Exclude '<symbols to exlude from your passphrase'
  Excludes symbols from your passphrase mangling
#### -Verbose
  Gives you extra information about the generation of your passphrase

## Output:

Lowercase Password Characters are White

Uppercase Password Characters are Red

Numerical Password Characters are Blue

All Other Password Characters are Green 
