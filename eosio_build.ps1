##########################################################################
# This is EOS bootstrapper script for Windows.
#
# If you going to install cmake standalone dont forget to add it to the PATH env.
# params options:
#   -help show help information
#   -clean cleans all projects libraries
#   -config=(Release|Debug)
#   -buildType=(full|dep|eos)
#   -extPath=($CURRENTFULLPATH\..\extdeps)
#   -mpirArch=(core2)
#   -toolset=(LLVM-vs2017)
##########################################################################

param(
[switch]$help,
[switch]$clean,
[string]$config="Debug",
[string]$buildType="full",
[string]$extPath="",
[string]$mpirArch="core2",
[string]$toolset="LLVM-vs2017"
)

#setup vars and functions
$CURRENTFULLPATH = (Get-Item -Path ".\" -Verbose).FullName
$configLower = "$config".ToLower()
if($extPath -like "") {
$extPath="$CURRENTFULLPATH\externals"
}

$PLATFORM_SYSTEM_VERSION = "10.0.17134.0"

function Test-BuildDep ($checkdirpath, $dependencyName)
{
	if(Test-Path -Path $checkdirpath) {
		Write-Host "`n--- Finished $dependencyName installation successfully ---`n" -ForegroundColor Green
	}
	else {
		Write-Host "`n--- $dependencyName installation failed ---`n" -ForegroundColor Red
		exit
	}
}

function Write-AlreadyInstalledDep($dependencyName) {
	Write-Host "`n--- $dependencyName already installed ---`n" -ForegroundColor Yellow
}

function AddMicrosoftPlataformToProject($pathToProject) {
	$xml = [xml] (type $pathToProject)
	[System.Xml.XmlNamespaceManager]$ns = $xml.NameTable
	$ns.AddNamespace("Any", $xml.DocumentElement.NamespaceURI)
	$globalNodeList = $xml.SelectNodes('//Any:PropertyGroup[@Label = "Globals"]', $ns)
	$targetPlatformNewNode = $xml.CreateElement("WindowsTargetPlatformVersion")
	$targetPlatformNewNode.InnerText = "$PLATFORM_SYSTEM_VERSION"
	$globalNodeList.item(0).AppendChild($targetPlatformNewNode)
	$xml = [xml] $xml.OuterXml.Replace(" xmlns=`"`"", "")
	$xml.Save($pathToProject) | Out-Null
}

function DownloadAndExtractDep($depName, $depURL, $outFile) {
	"Getting $depName from $depURL`n"
	Invoke-WebRequest $depURL -OutFile "$extPath\$outFile"

	"`Extracting $depName`n"
	if ("$outFile" -like '*.tar*') { 
		pushd ($extPath)
		perl -MArchive::Extract -e "Archive::Extract->new( archive => '$outFile' )->extract()"
		popd
	}
	else {
		Add-Type -AssemblyName System.IO.Compression.FileSystem
		[System.IO.Compression.ZipFile]::ExtractToDirectory("$extPath\$outFile", $extPath)
	}

	#Remove-Item "$extPath\$outFile" -ErrorAction Ignore
}

# Set build paths

$bzip2_LIBPATH         = "$extPath\bzip2-1.0.6\*.lib"
$zlib_LIBPATH          = "$extPath\zlib-1.2.11\install\lib"
$boost_LIBPATH         = "$extPath\boost_1_67_0\stage\lib"
$gettext_LIBPATH       = "$extPath\gettext-0.19.8\install\lib"
$openssl_LIBPATH       = "$extPath\openssl-1.1.0\build\lib"
$mpir_LIBPATH          = "$extPath\mpir-3.0.0\lib"
$secp256k1_zkp_LIBPATH = "$extPath\secp256k1-zkp\install\lib"
$wasm_compiler_LIBPATH = "$extPath\wasm-compiler\llvm\install\lib"
$eos_LIBPATH           = "install\lib"

# Execute actions

if($help) {
	echo "Usage: build.ps1 -config Release -buildType full"
	echo "Options: "
    echo "-help "
	echo "   show help information "
    echo "-config [mode] "
	echo "   Build with Release|Debug mode "
    echo "-buildType [type] "
	echo "   Build (full|dep|eos) types "
    echo "-extPath [path] "
	echo "   Set external dependencies path defaults to (..\extdeps) "
    echo "-mpirArch=(core2) "
	echo "   Set mpir build architecture defaults to (core2) "
	exit
}

if($clean) {
	Remove-Item $bzip2_LIBPATH         -Recurse -ErrorAction Ignore
	Remove-Item $zlib_LIBPATH          -Recurse -ErrorAction Ignore
	Remove-Item $boost_LIBPATH         -Recurse -ErrorAction Ignore
	Remove-Item $gettext_LIBPATH       -Recurse -ErrorAction Ignore
	Remove-Item $openssl_LIBPATH       -Recurse -ErrorAction Ignore
	Remove-Item $mpir_LIBPATH          -Recurse -ErrorAction Ignore
	Remove-Item $secp256k1_zkp_LIBPATH -Recurse -ErrorAction Ignore
	Remove-Item $wasm_compiler_LIBPATH -Recurse -ErrorAction Ignore
	Remove-Item $eos_LIBPATH           -Recurse -ErrorAction Ignore
	exit
}

#configure path variables if not configured previously

if(!($env:Path -like ("*cmake*"))) {
	$CMAKETOOLS = "E:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\"
	if(!(Test-Path -Path $CMAKETOOLS )){
		$CMAKETOOLS = "E:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\"
		if(!(Test-Path -Path $CMAKETOOLS )){
			$CMAKETOOLS = "E:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\"
			if(!(Test-Path -Path $CMAKETOOLS )){
				Write-Host "`nCMAKE TOOLS not found aborting build." -ForegroundColor Red
				exit
			}
		}
	}
	$env:Path += ";$CMAKETOOLS;"
}

if (!($env:Path -like ("*Windows Kits\10*"))) {
	# Configuring  visual studio x86_x64 Cross Tools command prompt variables to powershell
	$VS141COMNTOOLS = "E:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build"
	if(!(Test-Path -Path $VS141COMNTOOLS )){
		$VS141COMNTOOLS = "E:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build"
		if(!(Test-Path -Path $VS141COMNTOOLS )){
			$VS141COMNTOOLS = "E:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\VC\Auxiliary\Build"
			if(!(Test-Path -Path $VS141COMNTOOLS )){
				exit
			}
		}
	}
	
	$env:Path += ";C:\Windows\System32\wbem"

	pushd $VS141COMNTOOLS
	cmd.exe /c "vcvarsall.bat x64&set" |
	foreach {
	  if ($_ -match "=") {
		$v = $_.split("="); set-item -force -path "ENV:\$($v[0])"  -value "$($v[1])"
	  }
	}
	popd

	Write-Host "`nVisual Studio 2017 Command Prompt variables set." -ForegroundColor Yellow
}

if(!($buildType -eq "eos")) {
	#Begin creating EOS external deps
	Write-Host "`n--- Creating EOS external dependencies ---`n" -ForegroundColor Green

	if(!(Test-Path -Path $extPath )){
		"Creating external dependecies dir`n"
		New-Item -ItemType directory -Path $extPath | Out-Null
	}

	# Install bzip2-1.0.6
	if(!(Test-Path -Path $bzip2_LIBPATH )){
		pushd ("$extPath\bzip2-1.0.6")
		"`nBuilding bzip2 1.0.6`n"
		nmake -f makefile.msc
		popd
		Test-BuildDep $bzip2_LIBPATH "bzip2 1.0.6"
	}
	else {
		Write-AlreadyInstalledDep "bzip2 1.0.6"
	}

	#----------------------

	# Install zlib 1.2.11
	if(!(Test-Path -Path $zlib_LIBPATH )){
		"Configuring zlib 1.2.11`n"
		pushd ("$extPath\zlib-1.2.11")
		$NEWBUILDDIR = "build"
		New-Item -ItemType directory -Path "install" -ErrorAction Ignore | Out-Null

		& cmake -G "Visual Studio 15 2017 Win64" -T $toolset -B"$NEWBUILDDIR" -H"." -DCMAKE_INSTALL_PREFIX:PATH="$extPath\zlib-1.2.11\install" -DCMAKE_SYSTEM_VERSION="$PLATFORM_SYSTEM_VERSION"

		"`nBuilding zlib 1.2.11`n"
		& cmake --build $NEWBUILDDIR --config $config --target install
		popd
		Test-BuildDep $zlib_LIBPATH "zlib 1.2.11"
	}
	else {
		Write-AlreadyInstalledDep "zlib 1.2.11"
	}

	#----------------------

	# Install gettext 0.19.8
	if(!(Test-Path -Path $gettext_LIBPATH )){	
		"`nConfiguring gettext 0.19.8`n"
		pushd ("$extPath\gettext-0.19.8")
		$NEWBUILDDIR = "build"
		Remove-Item "install" -Recurse -ErrorAction Ignore | Out-Null
		New-Item -ItemType directory -Path "install" -ErrorAction Ignore | Out-Null

		& cmake -G "Visual Studio 15 2017 Win64" -T $toolset -B"$NEWBUILDDIR" -H"." -DCMAKE_INSTALL_PREFIX:PATH="$extPath\gettext-0.19.8\install" -DCMAKE_SYSTEM_VERSION="$PLATFORM_SYSTEM_VERSION"

		"`nBuilding gettext 0.19.8`n"
		& cmake --build $NEWBUILDDIR --config $config --target install
		popd

		Test-BuildDep $gettext_LIBPATH "gettext-0.19.8"
	}
	else {
		Write-AlreadyInstalledDep "gettext-0.19.8"
	}

	#----------------------

	# Install openssl 1.1.0
	if(!(Test-Path -Path $openssl_LIBPATH )){
		pushd ("$extPath\openssl-1.1.0")

		if($config -eq "Release") {
			$opensslConfig = "--release"
			$opensslZlib = "$extPath\zlib-1.2.11\install\lib\zlibstatic.lib"
		}
		else {
			$opensslConfig = "--debug"
			$opensslZlib = "$extPath\zlib-1.2.11\install\lib\zlibstaticd.lib"
		}

		"`nConfiguring openssl 1.1.0`n"
		& perl configure VC-WIN64A enable-capieng no-shared zlib no-zlib-dynamic threads $opensslConfig --openssldir="$extPath\openssl-1.1.0\build" --prefix="$extPath\openssl-1.1.0\build" --with-zlib-include="$extPath\zlib-1.2.11\install\include" --with-zlib-lib="$opensslZlib"

		"`nBuilding openssl 1.1.0`n"
		& nmake install
		popd
		Test-BuildDep $openssl_LIBPATH "openssl 1.1.0"
	}
	else {
		Write-AlreadyInstalledDep "openssl 1.1.0"
	}
	#----------------------

	# Install mpir 3.0.0
	if(!(Test-Path -Path $mpir_LIBPATH )){
		"`nConfiguring mpir-3.0.0`n"
		pushd ("$extPath\mpir-3.0.0\build.vc15")
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\dll_mpir_core2\dll_mpir_core2.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\dll_mpir_gc\dll_mpir_gc.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\dll_mpir_haswell_avx\dll_mpir_haswell_avx.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\dll_mpir_p3\dll_mpir_p3.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\dll_mpir_skylake_avx\dll_mpir_skylake_avx.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\lib_mpir_core2\lib_mpir_core2.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\lib_mpir_cxx\lib_mpir_cxx.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\lib_mpir_gc\lib_mpir_gc.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\lib_mpir_haswell_avx\lib_mpir_haswell_avx.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\lib_mpir_p3\lib_mpir_p3.vcxproj"
		AddMicrosoftPlataformToProject "$extPath\mpir-3.0.0\build.vc15\lib_mpir_skylake_avx\lib_mpir_skylake_avx.vcxproj"

		"`nBuilding mpir 3.0.0`n"
		& .\msbuild.bat "$mpirArch" LIB x64 "$config"
		popd

		Test-BuildDep $mpir_LIBPATH "mpir-3.0.0"
	}
	else {
		Write-AlreadyInstalledDep "mpir-3.0.0"
	}
	#----------------------

	# Install secp256k1-zkp
	if(!(Test-Path -Path $secp256k1_zkp_LIBPATH )){
		"`nConfiguring secp256k1-zkp`n"
		pushd ("$extPath\secp256k1-zkp")
		$NEWBUILDDIR = "build"
		New-Item -ItemType directory -Path "install" -ErrorAction Ignore | Out-Null

		& cmake -G "Visual Studio 15 2017 Win64" -T $toolset -B"$NEWBUILDDIR" -H"." -DCMAKE_INSTALL_PREFIX:PATH="$extPath\secp256k1-zkp\install" -DCMAKE_C_FLAGS="-I`"$extPath\mpir-3.0.0\lib\x64\$config`"" -DCMAKE_SYSTEM_VERSION="$PLATFORM_SYSTEM_VERSION"

		"`nBuilding secp256k1-zkp`n"
		& cmake --build $NEWBUILDDIR --config $config --target install -- /maxcpucount
		popd

		Test-BuildDep $secp256k1_zkp_LIBPATH "secp256k1-zkp"
	}
	else {
		Write-AlreadyInstalledDep "secp256k1-zkp"
	}
	#----------------------

	# Install wasm-compiler
	if(!(Test-Path -Path $wasm_compiler_LIBPATH )){
		"Configuring wasm-compiler`n"
		pushd ("$extPath\wasm-compiler\llvm")

		$NEWBUILDDIR = "build"

		New-Item -ItemType directory -Path "install" -ErrorAction Ignore | Out-Null

		& cmake -G "Visual Studio 15 2017 Win64" -T $toolset -B"$NEWBUILDDIR" -H"." -DLLVM_INCLUDE_TESTS=NO -DCMAKE_INSTALL_PREFIX:PATH="$extPath\wasm-compiler\llvm\install" -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly -DLLVM_USE_CRT_DEBUG=MDd -DLLVM_USE_CRT_RELEASE=MD -DCMAKE_SYSTEM_VERSION="$PLATFORM_SYSTEM_VERSION"

		"`nBuilding wasm-compiler`n"
		& cmake --build $NEWBUILDDIR --config $config --target install -- /maxcpucount
		popd
		Test-BuildDep $wasm_compiler_LIBPATH "wasm-compiler"
	}
	else {
		Write-AlreadyInstalledDep "wasm-compiler"
	}
	#----------------------

	Write-Host "`n--- Finished EOS external dependencies installation successfully ---`n" -ForegroundColor Green

	write-host "`n--- writing CMakeSettings.json ---`n" -ForegroundColor Green

	# create CMakeSettings.json
	$CMAKECOMMANDARGS = " -DBOOST_ROOT=$extPath\boost_1_67_0"
	$CMAKECOMMANDARGS += " -DIntl_INCLUDE_DIR=$extPath\gettext-0.19.8\install\include"
	$CMAKECOMMANDARGS += " -DIntl_LIBRARY=$extPath\gettext-0.19.8\install\lib\libintl.lib"
	$CMAKECOMMANDARGS += " -DZLIB_ROOT=$extPath\zlib-1.2.11\install"
	$CMAKECOMMANDARGS += " -DBZIP2_INCLUDE_DIR=$extPath\bzip2-1.0.6"
	$CMAKECOMMANDARGS += " -DBZIP2_LIBRARIES=$extPath\bzip2-1.0.6\libbz2.lib"
	$CMAKECOMMANDARGS += " -DGMP_DIR=$extPath\mpir-3.0.0\lib\x64\$config"
	$CMAKECOMMANDARGS += " -DSecp256k1_ROOT_DIR=$extPath\secp256k1-zkp\install"
	$CMAKECOMMANDARGS += " -DOPENSSL_ROOT_DIR=$extPath\openssl-1.1.0\build"
	$CMAKECOMMANDARGS += " -DOPENSSL_LIBRARIES=$extPath\openssl-1.1.0\build\lib"
	$CMAKECOMMANDARGS += " -DWASM_ROOT=$extPath\wasm-compiler\llvm\install"
	$CMAKECOMMANDARGS += " -DLLVM_DIR=$extPath\wasm-compiler\llvm\install\lib\cmake\llvm"
	$CMAKECOMMANDARGS += " -DBINARYEN_ROOT=$extPath\binaryen\install"
	$CMAKECOMMANDARGS += " -DCMAKE_INSTALL_PREFIX:PATH=$CURRENTFULLPATH\install"

	$CMAKECOMMANDARGS = $CMAKECOMMANDARGS -replace "\\", "\\"

	"{
	  // see https://go.microsoft.com//fwlink//?linkid=834763 for more information about this file.
	  `"configurations`": [
		{
		  `"name`": `"x64-Debug`",
		  `"generator`": `"Visual Studio 15 2017 Win64`",
		  `"configurationType`": `"Debug`",
		  `"buildRoot`": `"`${env.userprofile}\\cmakebuilds\\`${workspaceHash}\\build\\`${name}`",
		  `"cmakeCommandArgs`": `"$CMAKECOMMANDARGS`",
		  `"buildCommandArgs`": `"-m -v:minimal`",
		  `"ctestCommandArgs`": `"`"
		},
		{
		  `"name`": `"x64-Release`",
		  `"generator`": `"Visual Studio 15 2017 Win64`",
		  `"configurationType`": `"Release`",
		  `"buildRoot`": `"`${env.userprofile}\\cmakebuilds\\`${workspaceHash}\\build\\`${name}`",
		  `"cmakeCommandArgs`": `"$CMAKECOMMANDARGS`",
		  `"buildCommandArgs`": `"-m -v:minimal`",
		  `"ctestCommandArgs`": `"`"
		}
	  ]
	}" | out-file -encoding ascii CMakeSettings.json
	#----------------------
}

if(!($buildType -eq "dep")) {
	# Install eos
	$extPath = $extPath -replace "\\", "\\"

	if(!(Test-Path -Path $eos_LIBPATH )){
		"Configuring eos`n"
		$NEWBUILDDIR = "build"
		New-Item -ItemType directory -Path "install" -ErrorAction Ignore | Out-Null

		& cmake -A x64 -T $toolset -B"$NEWBUILDDIR" -H"." -DCMAKE_INSTALL_PREFIX:PATH="$CURRENTFULLPATH\\install" -DCMAKE_SYSTEM_VERSION="$PLATFORM_SYSTEM_VERSION" `
			-DBOOST_ROOT="$extPath\\boost_1_67_0" `
			-DIntl_INCLUDE_DIR="$extPath\\gettext-0.19.8\\install\\include" `
			-DIntl_LIBRARY="$extPath\\gettext-0.19.8\\install\\lib\\libintl.lib" `
			-DZLIB_ROOT="$extPath\\zlib-1.2.11\\install" `
			-DBZIP2_INCLUDE_DIR="$extPath\\bzip2-1.0.6" `
			-DBZIP2_LIBRARIES="$extPath\\bzip2-1.0.6\\libbz2.lib" `
			-DGMP_DIR="$extPath\\mpir-3.0.0\\lib\\x64\\$config" `
			-DSecp256k1_ROOT_DIR="$extPath\\secp256k1-zkp\\install" `
			-DOPENSSL_ROOT_DIR="$extPath\\openssl-1.1.0\\build" `
			-DOPENSSL_LIBRARIES="$extPath\\openssl-1.1.0\\build\\lib" `
			-DWASM_ROOT="$extPath\\wasm-compiler\\llvm\\install" `
			-DLLVM_DIR="$extPath\\wasm-compiler\\llvm\\install\\lib\\cmake\\llvm" `
			-DBINARYEN_ROOT="$extPath\\binaryen\\install"

		"`nBuilding eos`n"
		& cmake --build $NEWBUILDDIR --config $config --target install

		Test-BuildDep $eos_LIBPATH "eos"
	}
	else {
		Write-AlreadyInstalledDep "eos"
	}
}
