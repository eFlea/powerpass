<#
.SYNOPSIS
This script generates a strong password based on the Diceware Password Generation scheme (https://theworld.com/~reinhold/diceware.html)
and adds some automatic mangling to help resist cracking.
This should generate passwords that are relatively easy to type yet hard to crack.

.DESCRIPTION
This PowerShell script is intended to read the EFF large wordlist (https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt), 
then simulates rolling dice to generate words for a passphrase.
It concatenates those words into a passphrase, then adds a random number of symbols, and digits.  
Then it converts a random number of lowercase letters to uppercase, generating your final password.

.PARAMETER EFFWordlistPath
The path to the text file containing the EFF Large Wordlist. 

.PARAMETER NumWords
How many words should be generated in your passphrase.

.PARAMETER Verbose
Generates extra output explaining how your password is generated.

.EXAMPLE
PS> .\New-SecurePassword.ps1 -EFFWordlistPath "c:\users\username\Downloads\eff_large_wordlist.txt" -NumWords 8 -Verbose

.NOTES
Future improvements will include a WIZARD mode where you just let the script know whether you need a low, medium, 
or high security password, and whether you're going to need a typeable password or something that you'll just be copying out of a password wallet.
Also planned is the option to let the WIZARD know what restrictions a developer has placed on your password - 
e.g. no more than 20 characters, must use one of the following characters, may not use any of the following characters, etc. so that the WIZARD can
still create a strong password for you
#>
function Show-Help {
    Write-Host "Usage of $($MyInvocation.MyCommand.Name):"
    Write-Host "`t-EFFWordlistPath [string]: <MANDATORY> Path to the EFF Large Wordlist - You can find this at https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt if you don't already have it."
    Write-Host "`t-NumWords [int]: <MANDATORY> Defaults to How many words long your passphrase should be.  If you're not sure, 8 is 'Generally Strong'."
    Write-Host "`t-Exclude [string]: (Optional) Any symbols you'd like to avoid using in your password."
    Write-Host "`t-Verbose: Displays extra information about how your password is generated."
    Write-Host "`t-Help: Display this help message"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "`tPS> .\New-SecurePassword.ps1 -EFFWordlistPath "c:\users\username\Downloads\eff_large_wordlist.txt" -NumWords 8 -Exclude '$!@' -Verbose"
    Write-Host ""
    Write-Host "This script generates a strong password based on diceware and adds some automatic mangling to help resist cracking."
    Write-Host "This should generate passwords that are relatively easy to type yet hard to crack."
    exit
}



function Import-Wordlist {
    #Import the dictionary from a file
    param (
        [string]$FilePath
    )

    $dictionary =@{}
    $lines = Get-Content -Path $FilePath
    foreach ($line in $lines) {
        if ($line -match "(\d+)\s+(\w+)") {
            $dictionary[$matches[1]] = $matches[2]
        }
    }
    return $dictionary
}

function Roll-Dice {
    param(
        [int]$Count
    )

    $result = ""
    for ($i = 0; $i -lt $Count; $i++) {
        $result += Get-Random -Minimum 1 -Maximum 7
    }
    return $result
}

function Get-Words {
    param(
        [hashtable]$Dictionary,
        [int]$Rolls
    )

    $concatenatedResult = ""
    for ($i = 0; $i -lt $Rolls; $i++) {
        $key = Roll-Dice -Count 5 
        $word = $Dictionary[$key]
        Write-Verbose "You rolled $key, which maps to $word."
        if ($null -ne $word) {
            $concatenatedResult += $word
        } else {
            Write-Host "Key: $key does not exist in the dictionary."
        }
    }
    return $concatenatedResult
}

function Remove-LastNonSpecialDigit {
    #This isn't getting used right now but it'll be used later when we work out the whole password length truncation thing i just don't feel like fixing this tonight.
    # Look at the last character of the string, if it's not a special character or a digit we can remove it, if it is, go to its predecessor and check that.  loop till you find a candidate for removal.
    # We don't want to remove a special char or a digit we just added.
    param(
        [string]$InputString,
        [char[]]$SpecialCharacters
    )


    for ($i = $Inputstring.Length -1; $i -ge 0; $i--) {
        $char = $InputString[$i]
        if ($SpecialCharacters -notcontains $char -and $char -notmatch '\d') {
            return $InputString.Remove($i, 1)
        }
    }
    # We didn't find anything (This should never happen)
    return $InputString
}

function Write-MultiColorText {
    param(
        [string]$InputString
    )

    Write-Host ""
    Write-Host "Here's your new password."
    Write-Host ""

    foreach ($char in $InputString.ToCharArray()) {
        if ($char -cmatch '[a-z]') {
            Write-Host $char -NoNewLine -ForegroundColor White
        }
        elseif ($char -cmatch '[A-Z]') {
            Write-Host $char -NoNewLine -ForegroundColor Red
        }
        elseif ($char -cmatch '[0-9]') {
            Write-Host $char -NoNewLine -ForegroundColor Blue
        }
        else{
            Write-Host $char -NoNewLine -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host ""
    Write-Host "Please advised that if someone can read your screen right now, either through screenshots or other means, they can read this password."
    Write-Host "Have a nice day."
}

function New-SecurePassword {
    [CmdletBinding()]
    param(
        [switch]$Help,
        [string]$EFFWordlistPath,
        [int]$NumWords,
        [int]$PassLength,       #this is in here cuz i'm planning to put something in here about how you can alter these to fit stupid password requirements like they only accept 20 chars...
        [string]$Exclude = "" #Default to empty string, but see stupidity notes above, you might not be able to use certain symbols
    )
    if ($Help) {
        Show-Help
        exit
    }
        Write-Verbose "Ok, Let's generate a passphrase.  We start by rolling 5 dice $NumWords times, and we're going to match that up with words in the EFF wordlist to generate a passphrase for you."
        Write-Verbose "Let's get started."
        Write-Verbose ""
        #Generate a passphrase
        $wordDictionary = Import-Wordlist -FilePath $EFFWordlistPath
        $inputString = Get-Words -Dictionary $wordDictionary -Rolls $NumWords
        $PassLength = $inputString.Length # See stupidity above, for now we just use the whole thing, this would get removed when we want to go back to that

        Write-Verbose "Now that we have those words, we're going to concatentate them together to generate your passphrase."
        Write-Verbose "Here's your brand new Diceware(tm) Passphrase."
        Write-Verbose "$inputString"
        Write-Verbose ""
        Write-Verbose "But, we're not going to stop there.  We're going to mangle your passphrase for some extra security."
        Write-Verbose "We're going to add symbols, and digits to your passphrase, and we're also going to turn some of those lowercase characters to uppercase characters."
        Write-Verbose ""

        # If we need a shorter password because of requirements above, we can cut this down here
        if ($inputString.Length -gt $PassLength) {
            $truncatedString = $inputString.Substring(0, $PassLength)
        } else {
            $truncatedString = $inputString
        }
        $originalTruncatedString = $truncatedString

        # First we need to add symbols and digits
        # To keep things typeable, I've set this to 1/8, but this isn't great for small passphrases... Maybe this needs to be adjusted by # of words or based on the limitations the developers set?

        [int] $toMangle = $passLength/8
        # Add a little jitter so it's not too predictable
        $toMangle = ($toMangle + (Get-Random -Minimum -1 -Maximum 2))
        $numSymbols = Get-Random -Minimum 1 -Maximum $toMangle
        $numDigits = ($toMangle - $numSymbols)

        # Define our symbols list and exclude the ones we shouldn't use if the user had some of those
        $symbols = '!@#$%^&*()_+{}|:<>?-=[]\;,./ '
        $excludedSymbols = $Exclude.ToCharArray()
        $availableSymbols = $symbols.ToCharArray() | Where-Object { $excludedSymbols -notcontains $_ }

        if ($Exclude -ne "") {
            Write-Verbose "You told us to exclude the symbols $Exclude, so we're going to be careful to leave those out of your password."
        }

        # Add in symbols
        for ($i = 1; $i -le $numSymbols; $i++) {
            # For each of the symbols we decided to put in, select a random symbol and put it in a random spot
            $randomSymbol = $availableSymbols | Get-Random
            $randomLocation = Get-Random -Minimum 0 -Maximum $originalTruncatedString.Length
            $truncatedString = $truncatedString.Insert($randomLocation, $randomSymbol)

            #If we were doing the password length thing right now, we'd have to trim this
            #$truncatedString = $Remove-LastNonSpecialDigit -InputString $truncatedString -SpecialCharacters $availableSymbols
        }

        # Add in digits
        for ($i = 1; $i -le $numDigits; $i++) {
            # Same thing for digits
            $randomDigit = Get-Random -Minimum 0 -Maximum 10
            $randomLocation = Get-Random -Minimum 0 -Maximum $originalTruncatedString.Length
            $truncatedString = $truncatedString.Insert($randomLocation, $randomDigit)

            #If we were doing the password length thing right now, we'd have to trim this
            #$truncatedString = $Remove-LastNonSpecialDigit -InputString $truncatedString -SpecialCharacters $availableSymbols
        }

        Write-Verbose "We added $numSymbols symbols and $numDigits digits to that, which changed it to $truncatedString."

        # Add in uppercase letters
        # First we need to find out the location of all our lowercase letters
        $lowercasePositions = @()
        for ($i = 0; $i -lt $truncatedString.Length; $i++) {
            if ($InputString[$i] -cmatch '[a-z]') {
                $lowercasePositions += $i
            }
        }
        # Now we need to decide how many to convert... i'm just kinda letting this one go but maybe should restrict it to like.. no more than half? It feels... cluttered.
        $numletterstoConvert = Get-Random -Minimum 1 -Maximum ($lowercasePositions.Count)
        Write-Verbose "Then, we changed $numletterstoConvert lowercase letters to uppercase letters."
        $selectedPositions = Get-Random -InputObject $lowercasePositions -Count $numletterstoConvert
        $charArray = $truncatedString.ToCharArray()

        foreach ($pos in $selectedPositions) {
            $charArray[$pos] = [char]::ToUpper($charArray[$pos])
        }
    $truncatedString = -join $charArray
    Write-Verbose "That gave us your final password of $truncatedString!"
    Write-Verbose "And if you're curious about the math behind the strength of your password, I am too, I'm just kinda tired and I don't feel like working this out tonight."
    Write-Verbose "But here's the basics - There are 7776 words in the list, and you chose a passphrase with $numWords in it.  So, right off the bat, if you were only thinking about diceware, you've got a keyspace of 7776^$numWords that someone has to work through to crack just the passphrase without mangling."
    Write-Verbose "Wolfram is pretty good at doing this kinda math."
    Write-Verbose "But.  The mangling we've done changes things in a weird way because now we're not dealing with just the idea that each of the words is a 'character' in the keyspace, now we've introduced the idea that there could be symbols and digits in between random letters anywhere inside of any of those words or even between them."
    Write-Verbose "I think this should actually represent a pretty significant improvement over Diceware while still maintaining the human readable/typeable nature but I'm gonna have to do some math to prove that out.  Wanna help?"
    Write-MultiColorText -InputString $truncatedString
}