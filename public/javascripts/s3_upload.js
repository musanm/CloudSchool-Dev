function reset_values()
{
    var default_val = j('.field1').attr('default');
    j('.field1').val(default_val);
    j('.paper').val('');
}


function paperclip_file_upload(e, el)
{
    var no_file_chosen_label = 'No file selected';
    var el_id = el.id;
    var str = "#field_"+el_id;
    var file_value = el;
    if(j(el).attr('direct') == "true"){
        j(str).val(el.files[0].name.truncate(15));
        j(str).attr("title",el.files[0].name);
        j(el).attr("title",el.files[0].name);
    }
    else if(j(el).attr('direct') == "false")
    {
        var error_text = '#error_'+el.id;
        var upload_file_name=el.files[0].name
        var file = el.files[0];
        var max_file_size;
        var file_types;
        j(el).parent().children().each(function(ele,val){
            if(val.id.indexOf("max_file_size") >= 0){
                max_file_size = val.value;
            }else if(val.id.indexOf("file_types") >= 0){
                file_types = val.value;
            }
        });
        if(max_file_size > file.size && ((file_types.search(file.type) >= 0 && file_types.length != 0 && file.type.length != 0) || file_types.length == 0 )){
            j(error_text).attr("style","display: none");

            var pgb = "#progressbar_"+file_value.id;
            var pgb_out = "#progressbarout_"+file_value.id;
            var pgb_in = "#progressbarin_"+file_value.id;
            var label_text = '#field_'+file_value.id;

            j('#key_'+el_id).attr('value','temp/'+e.timeStamp+'/'+el.files[0].name);
//            var url = 'https://fedena_res.s3.amazonaws.com/';
            var url = s3_url;
            var xhr = new XMLHttpRequest();


            xhr.upload.addEventListener("loadstart", function(evt){
                j(label_text).attr("style","display: none");
                j(pgb).attr("style","display: inline-block");
                j('input[type=submit]').attr('disabled',true);
            }, false);
            xhr.upload.addEventListener("error", function(evt){
                file_value.value = '';
                if(form_enabled()==true)
                {
                    j('input[type=submit]').attr('disabled',false);
                }
                j(label_text).attr("style","display: inline-block");
                j(pgb).attr("style","display: none");

            });
            xhr.upload.addEventListener("abort", function(evt){
                file_value.value = '';
                if(form_enabled()==true)
                {
                    j('input[type=submit]').attr('disabled',false);
                }
                j(label_text).attr("style","display: inline-block");
                j(pgb).attr("style","display: none");
            });
            var t = null;
            xhr.upload.addEventListener("progress", function(evt){
                if(typeof t !== 'undefined' || t!=null){
                    clearTimeout(t);
                }
                t = setTimeout(function(e){
                    var timeout = true;
                    xhr.abort();
                },5000);
                var progressBar = j(pgb_out);
                var percentageDiv = document.getElementById(pgb_in);

                if (evt.lengthComputable) {

                    progressBar.max = evt.total;
                    progressBar.value = evt.loaded;
                    j(pgb_in).attr("style",'width:'+ Math.round(evt.loaded / evt.total * 100)+'px');

                }

            }, false);
            xhr.upload.addEventListener("load", function(evt){
                if(typeof t !== 'undefined' || t!=null){
                    clearTimeout(t);
                }
                j(pgb).attr("style","display: none");
                j(label_text).attr("style","display: inline-block");
                if(form_enabled()==true)
                {
                    j('input[type=submit]').attr('disabled',false);
                }
            }, false);
            xhr.onreadystatechange=function(){
                if (this.readyState==4&&null!=this.status&&(this.status==200||this.status==201
                    ||this.status==202||this.status==204||this.status==205||this.status==0)){
                    if(xhr.status == 201){
                        j(str).val(upload_file_name.truncate(15));
                        j(str).attr("title",upload_file_name);
                        j("#"+el_id+".paper").attr("title",upload_file_name);
                        j.event.trigger({
                            type: "upload",
                            message: file_value.id,
                            file_name: file.name,
                            time: new Date()
                        });
                        file_value.value = '';
                        var url_id=file_value.id
                        url = j(xhr.responseText).find('location').text() + '?content_type=' + file.type + '&file_size=' + file.size;//.gsub('%2F','/');
                        j("#"+url_id).get(0).type="hidden"
                        j("#"+url_id).get(0).value = url;
                    }
                    else if(xhr.status == 0 || xhr.status == 4 )
                    {
                        file_value.value = '';
                        j("#"+el_id).get(0).value=""
                        j("#"+el_id).get(0).type="file"
                        j(str).val(no_file_chosen_label);
                        j(str).attr("title","");
                        j(this).attr("title","No file chosen");
                        j.event.trigger({
                            type: "upload_failure",
                            message: file_value.id,
                            time: new Date()
                        });
                    }
                }else if (this.readyState==4){
                //console.log('fail ');
                }else if (this.readyState==400){
            //console.log('failed to upload');
            }
            }
            var params = {
                'key':j('#key_'+el_id).val(),
                'acl':j('#acl_'+el_id).val(),
                'success_action_status':j('#success_action_status_'+el_id).val(),
                'AWSAccessKeyId':j('#AWSAccessKeyId_'+el_id).val(),
                'policy':j('#policy_'+el_id).val(),
                'signature':j('#signature_'+el_id).val(),
                'file':file
            };

            var fData = new FormData();

            for(var p in params){
                fData.append(p,params[p]);
            }

            xhr.open("POST", url, true);
            xhr.send(fData);

        }
        else
        {
            upload_failure(file_value,error_text,el,str,no_file_chosen_label)
        }
    }
}

function upload_failure(file_value,error_text,el,str,no_file_chosen_label)
{
    file_value.value = '';
    j(error_text).attr("style","display: block");
    j("#"+el.id).get(0).value=""
    j("#"+el.id).get(0).type="file"
    j(str).val(no_file_chosen_label);
    j(str).attr("title","");
    j(el).attr("title","No file chosen");
    j.event.trigger({
        type: "upload_failure",
        message: file_value.id,
        time: new Date()
    });
}

function form_enabled()
{
    var enbl=true;
    j(".pgbar").each(function() {
        if(j( this ).css( "display" )!="none")
        {
            enbl = false;
        }
    });
    return enbl;
}

function abort()
{
    if(form_enabled()==true)
    {
        j('input[type=submit]').attr('disabled',false);
    }
}



j(document).ready(function(){
    reset_values();
});
