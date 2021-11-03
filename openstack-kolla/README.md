for i in $(find /var/lib/ -name kolla_extend_start);do if file $i|egrep -iq asci;then if egrep -iq horizon $i;then echo $i;fi;fi;done
#config_karbor_dashboard
#config_qinling_dashboard
#config_searchlight_ui




