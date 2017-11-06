# PSRunspacedDelegate

PowerShell module for creating delegates that can access the current PowerShell runspace.

Such delegates can be used for asynchronous programming, and enable PowerShell code to run in a separate thread.

## Installation

### Installation from GitHub

Just clone this directory into a Module directory should be enough:

```powershell
# go to the WindowsPowerShell directory:
cd (Split-Path $PROFILE);

# make the Modules directory if it does not exist:
if (-not (Test-Path Modules)) {
    mkdir Modules | Out-Null;
}

# cd to the Modules directory
cd Modules;

# clone the repository
git clone https://github.com/tahir-hassan/PSRunspacedDelegate.git --depth 1;
```

### Installation from PowerShell Gallery

To install it from the PowerShell Gallery, run the following command:

```powershell
Install-Module PSRunspacedDelegate -Scope CurrentUser
```

## Function Provided

Use the function `New-RunspacedDelegate` to create a delegate that has access to the PowerShell environment. 

The delegate that `New-RunspacedDelegate` produces will have the same type as the input delegate.  Therefore, if you pass a `Func<int, int>`, you will get a `Func<int, int>` as output.  If you pass `Action<string, List<string>>`, you will get the same type, `Action<string, List<string>>`, as its output. Simply put, if you pass an argument of type `T` (as long as `T` is a delegate type), you will get an object of type `T` as output.

## Examples

### Starting a new thread

Ordinarily, the following code will fail because we are creating and running a new thread to run PowerShell code:

```powershell
# BAD CODE - DO NOT DO THIS!
$writeToLog = [System.Threading.ThreadStart]{
   "hello" | Out-File C:\TEMP\temp.txt -Append;
};
$thread = [System.Threading.Thread]::new($writeToLog);
$thread.Start();
```

It fails because it is attempting to run PowerShell code in a new thread that has no access to a PowerShell runspace. 

Instead, if we pass the `ThreadStart` to `New-RunspacedDelegate`, it will create a new `ThreadStart` object that first sets the runspace to the current runspace, and then runs the (PowerShell) `ThreadStart` that was passed in.  Therefore it won't crash:

```powershell
#  This is OK
$writeToLog = New-RunspacedDelegate ([System.Threading.ThreadStart]{
   "hello" | Out-File C:\TEMP\temp.txt -Append;
});
$thread = [System.Threading.Thread]::new($writeToLog)
$thread.Start();
```

### Handling `Task<T>` tasks

You can use `ContinueWith` method to add a continuation to a task.  For instance, given a new task that returns the day of the week:

```powershell
$getDayOfWeek = New-RunspacedDelegate ( [Func[DayOfWeek]] { [DateTime]::Today.DayOfWeek; } );
$task = [System.Threading.Tasks.Task]::Run($getDayOfWeek);
```

You can chain a continuation with the `ContinueWith` method. 
```powershell
$continuation = New-RunspacedDelegate ( [Action[System.Threading.Tasks.Task[DayOfWeek]]] { param($t) Write-Host "Today is $($t.Result)" } );

$task.ContinueWith($continuation);
```
#### Access to variables

Local variables are not accessible from another thread.  However, `Script` and `Global` variables *can* be accessed.

For local variables, an easy way to access them is to use the `ContinueWith` method with the `object` state parameter.  You can pass in a hashtable containing the variables.

```powershell
# local variables we want to access in the delegate:
$name = "Tahir";     # name
$surname = "Hassan"; # surname
$score = 83;

# .........................

# create a hashtable of these local variables:
$locals = @{
    Name = $name;
    Surname = $surname;
    Score = $score;
};
```
Then call the `ContinueWith` method passing in the locals:
```powershell
$continuation = New-RunspacedDelegate ( [Action[System.Threading.Tasks.Task[DayOfWeek], object]] { 
    param($t,$info) 

    Write-Host "Today is $($t.Result)" -ForegroundColor Green;
    "Name: $( $info.Name ), Surname: $( $info.Surname ), Score: $( $info.Score )" | Write-Host -ForegroundColor Green; 
} );

$task.ContinueWith($continuation, $locals);
```

## Links

* <a href="http://www.get-blog.com/?p=189">Ryan's PowerShell Blog - True PowerShell Multithreading</a>
* <a href="https://stackoverflow.com/questions/34446404/powershell-cannot-spawn-a-new-thread">StackOverflow.com - PowerShell Thread Spawning Question</a>
