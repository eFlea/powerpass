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
        elseif ($char -cmatch '[\W]') {
            Write-Host $char -NoNewLine -ForegroundColor Green
        }
    }
    Write-Host ""
}

function New-SecurePassword {
    [CmdletBinding()]
    param(
        [string]$EFFWordlistPath,
        [int]$NumWords,
        [int]$PassLength,       #this is in here cuz i'm planning to put something in here about how you can alter these to fit stupid password requirements like they only accept 20 chars...
        [string]$Exclude = "" #Default to empty string, but see stupidity notes above, you might not be able to use certain symbols
    )
        #Generate a passphrase
        $wordDictionary = Import-Wordlist -FilePath $EFFWordlistPath
        $inputString = Get-Words -Dictionary $wordDictionary -Rolls $NumWords
        $PassLength = $inputString.Length # See stupidity above, for now we just use the whole thing, this would get removed when we want to go back to that

        Write-Verbose "We generated the following passphrase, consisting of $NumWords words."
        Write-Verbose "$inputString"

        # If we need a shorter password because of requirements above, we can cut this down here
        if ($inputString.Length -gt $PassLength) {
            $truncatedString = $inputString.Substring(0, $PassLength)
        } else {
            $truncatedString = $inputString
        }
        $originalTruncatedString = $truncatedString

        # First we need to add symbols and digits
        # To keep things typeable, I'm guessing we shouldn't add more than 1/4 of the total characters, but as this grows large, maybe that's too much?

        [int] $quarter = $passLength/4
        # Add a little jitter so it's not too predictable
        $quarter = ($quarter + (Get-Random -Minimum -1 -Maximum 2))
        $numSymbols = Get-Random -Minimum 1 -Maximum $quarter
        $numDigits = ($quarter - $numSymbols)

        # Define our symbols list and exclude the ones we shouldn't use if the user had some of those
        $symbols = '!@#$%^&*()_+{}|:<>?-=[]\;,./'
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
    Write-MultiColorText -InputString $truncatedString
}