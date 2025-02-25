function reset_values()
{
    var default_val = j('.field1').attr('default');
    j('.field1').val(default_val);
    j('.paper').val('');
}
function paperclip_file_upload(e, el)
{
    var el_id = el.id;
    var str = "#field_"+el_id;
    j(str).val(el.files[0].name.truncate(15));
    j(str).attr("title",el.files[0].name);
    j(el).attr("title",el.files[0].name);
}

j(document).ready(function(){
    reset_values();
//j('input[type=file]').on('change', (function (e){}));
});