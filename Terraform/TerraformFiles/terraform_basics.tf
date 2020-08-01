variable "x"{
	type= string
	default="sg1,sg2,sg3"
}

oupt "my_output"{
	value = elemt(split(",",var.x),0)
}


variable "y"{
	type=map
	default = {
		"us"="ami-1"
		"in"="ami-2"
	}
}

output "myop"{
	value = var.y["in"]
	value = lookup(var.y,"in")
}

output "myop1"{
	value = map("us","ami-1","in","ami-2")
	value = substr(var.x,-2,2)	#op - g3
	value = [for i in var.x: upper(i)]
	value = {for k,v in var.y: "${k}:${v}"}
	value = {for k,v in var.y: k=>v}
}














































