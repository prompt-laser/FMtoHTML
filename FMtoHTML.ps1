function New-Label($o){
	return New-Object -Type PSObject -Property @{top=$o.bounds.top;left=$o.bounds.left;width=$o.bounds.right-$o.bounds.left;height=$o.bounds.bottom-$o.bounds.top}
}

function New-Input($o){
	return New-Object -Type PSObject -Property @{top=$o.bounds.top;left=$o.bounds.left;width=$o.bounds.right-$o.bounds.left;height=$o.bounds.bottom-$o.bounds.top}
}

function New-TabControl($o){
	$control = New-Object -Type PSObject -Property @{ `
		top=$o.bounds.top; `
		left=$o.bounds.left; `
		width=$o.bounds.right-$o.bounds.left; `
		height=$o.bounds.bottom-$o.bounds.top; `
		tabs=@() `
	}
	
	ForEach($tco in $o.TabControlObj.Object){
		$control.tabs += New-Object -Type PSObject -Property @{ `
			tabtext=(($tco.titlecalc.calculation | ConvertTo-CSV -NoType | ConvertFrom-CSV -Header d)[1]).d; `
			tabLeft=$tco.TabPanelObj.tabLeftEdge; `
			tabWidth=$tco.TabPanelObj.tabWidth; `
			inputs=@(Get-Inputs($tco.TabPanelObj)); `
			labels=@(Get-Labels($tco.TabPanelObj)); `
		}
	}
	
	return $control
}

function Get-Labels($container){
	$l = @()
	ForEach($o in $container.object){
		If($o.type -eq "Text"){
			$l += New-Label($o)
		}
	}
	return $l
}

function Get-Inputs($container){
	$i = @()
	ForEach($o in $container.Object){
		If($o.Type -eq "Field"){
			$i += New-Input($o)
		}
	}
	return $i
}

function Get-TabControls($container){
	$t = @()
	ForEach($o in $container.Object){
		If($o.Type -eq "TabControl"){
			$t += New-TabControl($o)
		}
	}
	return $t
}

$xml = [xml](Get-Content c:\filemaker\contacts_fmp12.xml)

ForEach($file in $xml.fmpreport.file){
	ForEach($layout in $file.layoutcatalog.group.layout){
		$labels = @()
		$inputs = @()
		$labels = Get-Labels($layout)
		$inputs = Get-Inputs($layout)
		$TabControls = Get-TabControls($layout)

		$path = "c:\filemaker\output\" + $layout.name.replace(" ","_") + ".html"
		
		"<html><body bgcolor=#bbbbbb>" | Out-File $path
		"<script>" | Out-File $path -Append
		"function TabControl(p,c){" | Out-File $path -Append
		"document.getElementById(c).style.display = 'block';" | Out-File $path -Append
		"}" | Out-File $path -Append
		"</script>" | Out-File $path -Append

		ForEach($l in $labels){
			"<div style='background-color:#ffffff;position:absolute;top:" + $l.top + ";left:" + $l.left + ";min-width:" + $l.width + ";max-width:" + $l.width + ";min-height:" + $l.height + ";max-height:" + $l.height + "'></div>" | Out-File $path -Append
		}
		
		ForEach($i in $inputs){
			"<input type=text style='position:absolute;top:" + $i.top + ";left:" + $i.left + ";min-width:" + $i.width + ";max-width:" + $i.width + ";min-height:" + $i.height + ";max-height:" + $i.height + "' />" | Out-File $path -Append
		}
		
		$i = 0
		ForEach($t in $TabControls){
			"<div style='border-style:solid;border-width:2px;border-color:black;position:relative;top:" + $t.top + ";left:" + $t.left + ";min-width:" + $t.width + ";max-width:" + $t.width + ";min-height:" + $t.height + ";max-height:" + $t.height + "'>" | Out-File $path -Append
			"<div width=100%>" | Out-File $path -Append
			$c = 0
			ForEach($tab in $t.tabs){
				"<div style='display:inline-block' onClick='TabControl(`"" + $i + "`",`"" + $c + "`")'>" + $tab.tabText + "</div>" | Out-File $path -Append
				$c++
			}
			$c = 0
			"</div>" | Out-File $path -Append
			ForEach($tab in $t.tabs){
				"<div id='" + $c + "' style='display:none'>" | Out-File $path -Append
				ForEach($ti in $tab.inputs){
					"<input type=text style='position:fixed;display:inline-block;top:" + $ti.top + ";left:" + $ti.left + ";min-width:" + $ti.width + ";max-width:" + $ti.width + ";min-height:" + $ti.height + ";max-height:" + $ti.height + "' />" | Out-File $path -Append
				}
				ForEach($tl in $tab.labels){
					"<div style='display:inline-block;position:fixed;background-color:#ffffff;top:" + $tl.top + ";left:" + $tl.left + ";min-width:" + $tl.width + ";max-width:" + $tl.width + ";min-height:" + $tl.height + ";max-height:" + $tl.height + "'></div>" | Out-File $path -Append
				}
				"</div>" | Out-File $path -Append
				$c++
			}
			$c = 0
			$i++
			"</div>" | Out-File $path -Append
		}
		$i = 0
			
		"</body></html>" | Out-File $path -Append
		
		$labels = @()
		$inputs = @()
	}
}
