# New-SecurePassword.ps1
This generates a mangled Diceware Passphrase for use as a password.

NOTE!

I haven't yet proved that my scheme actually generates good passwords, this is a PoC.
USE YOUR PASSWORD MANAGER TO GENERATE PASSWORDS.

## Usage:
You must specify the path to the wordlist and how many words you want in your passphrase.

You must specify a minimum of 6 words to get a cracking resistant passphrase (Without Mangling).

#### PS> .\New-SecurePassword.ps1 -EFFWordlist \<Path to EFF Wordlist\> -NumWords \<num\>

## Required:

#### -EFFWordlist
  Path to EFFWordlist

#### -NumWords
  Number of Words to Generate in your Passphrase.

## Options:

#### -NoMangle
  Makes a true Diceware Passphrase without adding symbols or digits
#### -Exclude '<symbols to exlude from your passphrase'
  Excludes specific symbols from your passphrase mangling - i.e. don't use @ in my passphrase
#### -Verbose
  Gives you extra information about the generation of your passphrase
#### -Help
  Shows Help


## Output:

Lowercase Password Characters are White

Uppercase Password Characters are Red

Numerical Password Characters are Blue

All Other Password Characters are Green 
