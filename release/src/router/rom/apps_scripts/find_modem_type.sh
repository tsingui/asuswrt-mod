#!/bin/sh
# environment variable: unit - modem unit.
# echo "This is a script to find the modem type out."


node_home=/sys/devices
modem_enable=`nvram get modem_enable`
modem_method=`nvram get modem_method`
modem_model=`nvram get modem_model`
usb_gobi2=`nvram get usb_gobi2`
productid=`nvram get productid`

if [ -z "$unit" -o "$unit" -eq "0" ]; then
	prefix="usb_modem_"
else
	prefix="usb_modem${unit}_"
fi

modem_act_path=`nvram get ${prefix}act_path`
home="$node_home/"`cd $node_home && find -name "$modem_act_path" 2>/dev/null`
modem_vid=`cat $home/idVendor 2>/dev/null`
modem_pid=`cat $home/idProduct 2>/dev/null`

if [ "$modem_vid" == "" -o "$modem_pid" == "" ]; then
	echo "type=unknown"
	nvram set ${prefix}act_type=
	exit 0
fi


_find_act_type(){
	nodes=`cd $home && ls -d $modem_act_path:* 2>/dev/null`

	got_tty=0
	got_ecm=0
	got_other=0
	for node in $nodes; do
		path=`readlink -f $home/$node/driver 2>/dev/null`

		t=${path##*drivers/}
		if [ "$t" == "cdc_ether" ]; then
			got_ecm=1
			continue
		elif [ "$t" == "option" -o "$t" == "usbserial" -o "$t" == "usbserial_generic" ]; then
			got_tty=1
			continue
		elif [ "$t" == "cdc_acm" -o "$t" == "acm" ]; then
			got_tty=1
			continue
		elif [ "$t" == "rndis_host" ]; then
			got_other=1
			echo "rndis"
			break
		elif [ "$t" == "asix" -o "$t" == "ax88179_178a" ]; then
			got_other=1
			echo "asix"
			break
		elif [ "$t" == "qmi_wwan" -o "$t" == "qmi_wwan_q" ]; then
			got_other=1
			echo "qmi"
			break
		elif [ "$t" == "cdc_ncm" ]; then
			got_other=1
			echo "ncm"
			break
		elif [ "$t" == "cdc_mbim" ]; then
			got_other=1
			echo "mbim"
			break
		elif [ "$t" == "GobiNet" ]; then
			got_other=1
			echo "gobi"
			break
		elif [ "$t" == "ipheth" ]; then
			got_other=1
			echo "ipheth"
			break
		fi
	done

	if [ $got_other -ne 1 ]; then
		if [ $got_ecm -eq 1 ]; then
			echo "ecm"
		elif [ $got_tty -eq 1 ]; then
			echo "tty"
		else
			echo "tty"
		fi
	fi
}

if [ "$modem_method" == "tty" ]; then
	type="tty"
else
	type=`_find_act_type`
	if [ "$usb_gobi2" == "1" ]; then
		type="gobi"
	elif [ "$modem_enable" == "4" ]; then
		type="wimax"
	# Some dongles are worked strange with QMI. e.q. Huawei EC306.
	elif [ "$modem_enable" == "2" -a "$type" == "qmi" ]; then
		type="tty"
	elif [ "$modem_vid" == "19d2" -a "$modem_pid" == "1589" ]; then # ZTE MF193A
		type="tty"
	fi
fi
echo "type=$type."

nvram set ${prefix}act_type=$type

