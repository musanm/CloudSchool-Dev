var allocation_type,selected_tt,month_year;
var timetable,batches,all_batches,batch_subjects,employees,timings,allocated_class,weekday,classroom_allocations,class_rooms,elective_subjects,emp_subjects;
var sub,selected_day,prefix,start,end,classroom_id,sname,sub_id,e_id,ename,id_attr,x,originalBg, allocation_box;
var cname,drag_element,search_batches = {},dir;
var test, current_date;

function getjson(val,type) {
    // fetching data required for weekly allocation
    if ( type == "weekly") {
        $('loader2').show();
        allocation_type = type;
        selected_tt = val[0];
        new Ajax.Request('/classroom_allocations/weekly_allocation.json',{
            parameters: {
                timetable_id: val,
                alloc_type: type
            },
            asynchronous:true,
            evalScripts:true,
            method:'get',
            onComplete:function(resp){
                j('#loader2').hide();
                allocationBuilder(resp.responseJSON);
            }
        });
    }
    // fetching data for data specific allocation
    else if (type == "date_specific"){
        $('loader').show();
        allocation_type = type;
        month_year = val[0]+'-'+val[1];
        selected_day = 0;
        new Ajax.Request('/classroom_allocations/date_specific_allocation.json',{
            parameters: {
                date: month_year,
                alloc_type: type
            },
            asynchronous:true,
            evalScripts:true,
            method:'get',
            onComplete:function(resp){
                j('#loader').hide();
                allocationBuilder(resp.responseJSON);
            }
        });
    }
}


function allocationBuilder(respjson){
    test = respjson;
    timetable = respjson.timetable_entries;
    batches = respjson.batches;
    all_batches = batches;
    batch_subjects = respjson.subjects;
    employees = respjson.employees;
    timings = respjson.classtimings;
    allocated_class= respjson.allocated_classrooms;
    weekday = respjson.days;
    classroom_allocations = respjson.classroom_allocations;
    class_rooms = respjson.classrooms
    elective_subjects = respjson.elective_subjects
    emp_subjects = respjson.emp_subjects

    //  Header

    var header = drawHeader(); // Draw header
    j('.allocations').html(header);

    j('li.days a').hover(
        function() {
            j( this ).addClass( "themed_text" );
        },function() {
            j( this ).removeClass( "themed_text" );
        }
        );   // changing day name to theme color on hover

    addListScroller(); // attaching slider for date specific

    j("#my-als-list").als({
        visible_items: 7,
        scrolling_items: 7,
        orientation: "horizontal",
        autoscroll: "yes",
        interval: 60000000,
        speed: 400,
        easing: "linear",
        direction: "right",
        start_from: 7
    });

    if (allocation_type == "weekly"){
        selected_day = weekday[0][0];
        j('.days a#'+selected_day).addClass("active_day").addClass("themed_text");
    }
    else{
        j('.days a#0').addClass("active_day").addClass("themed_text");
    }  // setting theme color for active day


    //Allocation box
    allocation_box = document.createElement('div').addClassName("alloc_box");
    var box = drawBox();
    j(allocation_box).html(box);
    j('.allocations').append(allocation_box);
    drawEmptyBox();
    makeDroppable();

    // Buildings & Rooms

    renderRooms();

    // Search batch
    j(".batch_search").on({
        "keypress": function(){
            searchBatches();
        },
        "keyup": function(){
            searchBatches();
        },
        "change": function(){
            searchBatches();
        }
    })

}

function drawHeader(){
    var header = document.createElement('div').addClassName("header");
    var search = document.createElement('div').addClassName("search");
    var weekdays = document.createElement('div').addClassName("weekdays");
    var days = document.createElement('li').addClassName("days");
    var day = document.createElement('a').addClassName("day");

    var search_box = document.createElement('input').addClassName("batch_search");
    j(search_box).attr({
        type: "text",
        id: "search",
        placeholder: search_batch,
        size: "16",
        maxlength: "64"
    });

    var month = document.createElement('div').addClassName("show_month");
    j(search).append(search_box);
    j(header).append(search);

    if (allocation_type == "date_specific") month.textContent =  month_names[(new Date(month_year + "-01")).getMonth()] + ' ' + (new Date(month_year + "-01")).getUTCFullYear();
    if (allocation_type == "weekly") {
        j(search).css({
            "border": "0px"
        });
    }
    j(header).append(weekdays);
    j(search).append(month);

    for (var i = 0; i < weekday.length ; i++){
        if (allocation_type == "weekly"){
            weekday_text=weekday[i][1];
            weekday_id=weekday[i][0];
        }
        else{
            weekday_text=weekday[i];
            weekday_id=i;
        }

        var d =  j(day).clone().text(weekday_text);
        j(d).attr({
            "id":weekday_id,
            "class":"day"
        });
        var ds = j(days).clone().html(d);
        ds.appendTo(weekdays);
        j(d).click(function(){
            showAllocationForDay(this);
        })
    }
    return header;

}

function addListScroller(){
    if ( allocation_type == "date_specific") {
        j('.days').addClass("als-item");
        j('.weekdays').addClass("als-wrapper");

        var als_container = document.createElement('div').addClassName("als-container");
        j(als_container).attr({
            id: "my-als-list"
        });

        j('.weekdays').wrap(als_container);

        var span_prev = document.createElement('span').addClassName("als-prev");
        j(span_prev).insertBefore( ".weekdays" );
        j(span_prev).append("<div class='clickable1'></div>")

        var als_viewport = document.createElement('div').addClassName("als-viewport");
        j('.als-wrapper').wrap(als_viewport);

        var span_next = document.createElement('span').addClassName("als-next");
        j(span_next).insertAfter(".als-viewport");
        j(span_next).append("<div class='clickable2'></div>")
    }
}



function showAllocationForDay(obj){
    j('.alloc_box').addClass("transparency");
    var loader_src = j('#loader1')[0].src;
    j('.allocations').append("<img src=" + loader_src +"align = 'absmiddle' border = '0'  style = 'display:none' id ='loader3'></img><span id= 'loading_text'>Loading...</span>")
    j('.days a.active_day').removeClass('active_day').removeClass("themed_text").addClass('day')
    j(obj).removeClass("day").addClass("active_day").addClass("themed_text");
    selected_day = j(obj).attr('id');
    j('#loader3').show();

    j.get('/classroom_allocations/find_allocations', function(result) {
        allocated_class = result.allocations;
        classroom_allocations = result.classroom_alloc;
        j('#loader3').hide();
        j('#loading_text').remove();
        j('.alloc_box').removeClass("transparency");
        var box = drawBox();
        j(allocation_box).html(box);
        drawEmptyBox();
        makeDroppable();
    })
}


function drawBox(){
    var box = document.createElement('div').addClassName("box");
    var section = document.createElement('div').addClassName("section");
    var batch_name = document.createElement('div').addClassName("name themed_text");
    var batch_text = document.createElement('div').addClassName("batch_text");
    var subjects = document.createElement('div').addClassName("subjects");
    var sub_name = document.createElement('div').addClassName("sub");
    var sub_text = document.createElement('div').addClassName("sub_text");
    var emp_text = document.createElement('div').addClassName("emp_text");
    var tooltip_content = document.createElement('div').addClassName("tt_content");

    for (var key in batches){
        var sec = j(section).clone();
        var batch = j(batch_name).clone();
        var bt = j(batch_text).clone().text(batches[key]);
        sub = j(subjects).clone();
        var flag;
        test.tt.each(function(c){
            timetable[key].select(function(s){
                var dd = String(parseInt(selected_day) + 1);
                if (dd.length == 1) dd = "0" + dd;
                allocation_type == "weekly" ? condition = 1 : condition = ((month_year + "-" + dd ) >= c.timetable.start_date && (month_year + "-" + dd ) <= c.timetable.end_date && s.timetable_entry.batch_id == key && c.timetable.id == s.timetable_entry.timetable_id );
                //(c.timetable.id == s.timetable_entry.timetable_id && (parseInt(selected_day) + 1 >= new Date(c.timetable.start_date).getDate() && parseInt(selected_day) + 1 <= new Date(c.timetable.end_date).getDate()) );
                if (condition){
                    if (allocation_type == "date_specific" ){
                        d = month_year + '-' + dd;
                        current_date = d;
                        var selected_day1 = new Date(Date.parse(d)).getDay();
                    }
                    else{
                        var selected_day1 = selected_day;
                    }
                    if (s.timetable_entry.weekday_id == selected_day1) {
                        var sub_details={};
                        var emp_details;
                        j(sec).attr("id",key);
                        j(batch).append(bt);
                        j(sec).append(batch);
                        j(sec).append(sub);
                        j(box).append(sec);
                        batch_subjects[key].select(function(y){
                            if(y.subject.id == s.timetable_entry.subject_id){
                                sub_details[y.subject.id] = y.subject.name
                                if (y.subject.elective_group_id != nil){
                                    elective_subjects.select(function(es){
                                        es.each(function(i){
                                            if ( i.subject.elective_group_id == y.subject.elective_group_id ){
                                                sub_details[i.subject.id] = i.subject.name;
                                            }
                                        })
                                    })
                                }
                            }
                        });

                        emp_details = emp_subjects;
                        test.classtimings.select(function(t){
                            if (t.class_timing.id == s.timetable_entry.class_timing_id) {
                                var st = new Date(t.class_timing.start_time);
                                prefix = st.getUTCHours() >= 12 ? 'pm' : 'am'
                                start = parseFloat(st.getUTCHours() +"."+ st.getUTCMinutes()).toFixed(2) + prefix;
                                var et = new Date(t.class_timing.end_time);
                                prefix = et.getUTCHours() >= 12 ? 'pm' : 'am'
                                end = parseFloat(et.getUTCHours() +"."+ et.getUTCMinutes()).toFixed(2) + prefix;
                            }
                        });

                        var classroom = {};
                        var classroom_ids = {};
                        var allocation_dates = {}
                        classroom[s.timetable_entry.subject_id] = [];
                        classroom_ids[s.timetable_entry.subject_id] = [];
                        if (allocation_type == "date_specific"){
                        j.each(sub_details, function( index, value ) {
                            classroom[index] = {};
                            classroom_ids[index] = {};
                        })

                        for(day = 1; day <= 31 ; day++){
                            if (String(day).length == 1) {day = "0" + String(day)};
                            classroom_ids[s.timetable_entry.subject_id][month_year + "-" + day] = []
                            classroom[s.timetable_entry.subject_id][month_year + "-" + day] = []

                        }
                        }
                        else{
                                j.each(sub_details, function( index, value ) {
                            classroom[index] = [];
                            classroom_ids[index] = [];
                        })
                        }
                        

                        allocated_class.select(function(c){
                            if (c.allocated_classroom.timetable_entry_id == s.timetable_entry.id){
                                if (allocation_type == "date_specific" && c.allocated_classroom.date != nil){
                                    class_rooms.select(function(cr){
                                        if (cr.classroom.id == c.allocated_classroom.classroom_id){
                                            classroom[c.allocated_classroom.subject_id][c.allocated_classroom.date].push(cr.classroom.name);
                                            classroom_ids[c.allocated_classroom.subject_id][c.allocated_classroom.date].push(cr.classroom.id);

                                        }
                                    })
                                }
                                else if (allocation_type == "weekly" && c.allocated_classroom.date == nil){
                                    class_rooms.select(function(cr){
                                        if (cr.classroom.id == c.allocated_classroom.classroom_id){
                                            classroom[c.allocated_classroom.subject_id].push(cr.classroom.name);
                                            classroom_ids[c.allocated_classroom.subject_id].push(cr.classroom.id);
                                        }
                                    })
                                }
                            }
                        });
                        var flag = 0;
                        j.each(sub_details, function( index, value ) {
                            flag = flag + 1;
                            sname = value;
                            sub_id = index;
                            e_id = Object.keys(emp_details[index])[0];
                            ename = emp_details[index] == undefined ? no_teacher : emp_details[index][e_id];
                            flag > 1 ?  id_attr = s.timetable_entry.id + flag : id_attr = s.timetable_entry.id;
                            var m = j(sub_text).clone().text(sname);
                            var n = j(emp_text).clone().text(ename);
                            x = j(sub_name).clone();
                            j(x).append(m);
                            j(x).append(n);
                            j(x).hover(
                                function () {
                                    originalBg =j(this).css("background-color");
                                    j(this).css({
                                        'background-color' : '#ffffcd'
                                    });
                                },
                                function () {
                                    j(this).css({
                                        'background-color' : originalBg
                                    });
                                }
                                );


                            j(x).attr({
                                "id": 'sub' + id_attr
                            });
                            var subtooltip = "<div class='tooltip subtooltip'><div class='timing'>"+ start + " - " + end + "</div>" + "<div class='sub_text1'>" + sname +"</div>"
                            if (emp_details[index] != undefined){
                                emp_details[index].each(function(e){
                                    subtooltip = subtooltip + "<div class='emp_text1'>" + e + "</div>"
                                })
                            }
                            else{
                                subtooltip = subtooltip + "<div class='emp_text1'>" + no_teacher + "</div>"
                            }


                            subtooltip = subtooltip + "</br>"
                            j(x).data("info",{
                                "sname": sname,
                                "ename": ename,
                                "start":start,
                                "end":end ,
                                "classroom_id": classroom_ids,
                                "batch_id": key,
                                "emp_id": e_id,
                                "sub_id": sub_id,
                                "weekday_id": selected_day,
                                "class_timing_id": s.timetable_entry.class_timing_id,
                                "tte_id": s.timetable_entry.id
                            });
                            j(x).data({"date" : current_date})
                            j.each(classroom,function(key,el){
                                  if (key == sub_id && el[current_date] != undefined && allocation_type == "date_specific"){
                                    el[current_date].each(function(e,i){

                                        subtooltip = subtooltip + "<div class='room_name'" + "id=" + classroom_ids[key][current_date][i] + ">" + "<span id= 'rname' >" +e + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>"
                                    });
                                  }
                                  if (key == sub_id && allocation_type == "weekly"){
                                    el.each(function(e,i){
                                    subtooltip = subtooltip + "<div class='room_name'" + "id=" + classroom_ids[key][i] + ">" + "<span id= 'rname' >" +e + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>"
                                  });
                                }
                            });

                            subtooltip = subtooltip + "</div"
                            j(this).children('.arrow_box').css({
                                "display": "none"
                            });

                            j(x).append(subtooltip);
                            j(x).click(function(){
                                j(this).children('.subtooltip').css({
                                    "display": "block"
                                });
                                if (dir == 'rtl'){
                                    if (j('.alloc_box').position().left > (j(this).position().left)){
                                        j(this).children('.subtooltip').addClass("tooltip_case").removeClass("tooltip")
                                    }
                                    if (j('.alloc_box').position().top < (j(this).position().top )){
                                        j(this).children('.subtooltip').addClass("arrow_box").removeClass("tooltip")
                                    }
                                }
                                else{
                                    if (j('.alloc_box').position().left  + j('.alloc_box').width() < (j(this).position().left + j(this).width() + 155)){
                                        j(this).children('.subtooltip').addClass("tooltip_case").removeClass("tooltip")
                                    }

                                    if (j('.alloc_box').position().top  + j('.alloc_box').height() < (j(this).position().top + j(this).height() + 155)){
                                        j(this).children('.subtooltip').addClass("arrow_box").removeClass("tooltip")
                                    }

                                    if (j('.alloc_box').position().left  + j('.alloc_box').width() < (j(this).position().left + j(this).width() + 155) & j('.alloc_box').position().top  + j('.alloc_box').height() < (j(this).position().top + j(this).height() + 155)){
                                        j(this).children('.subtooltip').addClass("arrow_box").removeClass("tooltip")
                                    }
                                }

                                j('.sub').mouseleave(function(){
                                    j('.subtooltip').hide();
                                    j('.tooltip_case').hide();
                                    j('.arrow_box').hide();
                                });
                                j(this).children('.subtooltip').mouseleave(function(){
                                    j(this).hide();
                                });

                                j(this).children('.tooltip_case').mouseleave(function(){
                                    j(this).hide();
                                });

                                j(this).children('.arrow_box').mouseleave(function(){
                                    j(this).hide();
                                });
                            });

                            j(sub).append(x);

                            allocated_class.select(function(c){
                                if (c.allocated_classroom.timetable_entry_id == s.timetable_entry.id && c.allocated_classroom.subject_id == sub_id ){
                                    if (allocation_type == "date_specific" && c.allocated_classroom.date != nil && c.allocated_classroom.date == current_date){
                                      j(x).css("background-color","#ffe7e7");
                                    }
                                    else if(allocation_type == "weekly"){
                                        classroom_allocations.select(function(ca){
                                            if (ca.classroom_allocation.id == c.allocated_classroom.classroom_allocation_id && ca.classroom_allocation.allocation_type == "weekly"){
                                                j(x).css("background-color","#ffe7e7");
                                            }
                                        });
                                    }
                                }
                            });


                        });
                    }
                }
            })
        });
    }
    return box;
}


function drawEmptyBox(){
    var max_width = j('.box').width();
    j('.section').each(function(s){
        var width = j(this).children('.subjects').width();
        while(width<(max_width-35)){
            var x = "<div class='empty_box'></div>"; //j(j(this).children('.subjects').children('.sub')).first().cloneNode();
            width = width + j(j(this).children('.subjects').children('.sub')).first().width();
            j(this).children('.subjects').append(x);
        }
    })
}

function renderRooms(){
    j.get('/classroom_allocations/render_classrooms', function(result) {
        j('.allocations').append(result);
    });
}


function makeDroppable(){
    j('.sub').droppable({
        drop: function( event, ui ) {
            var jthis = j(this).attr('id');
            cname = j(this).attr('id');
            drag_element = ui.draggable.attr('id');
            new Ajax.Request('/classroom_allocations/update_allocation_entries',{
                parameters: {
                    classroom_id: j('#' + ui.draggable.attr('id')).attr("data"),
                    subject_id: j('#' + cname).data("info")["sub_id"],
                    emp_id: j('#' + cname).data("info")["emp_id"],
                    batch_id: j('#' + cname).data("info")["batch_id"],
                    alloc_type: allocation_type,
                    date: month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1),
                    timetable: selected_tt,
                    weekday: parseInt(j('.active_day').attr("id")),
                    classtiming: j('#' + cname).data("info")["class_timing_id"],
                    tte_id: j('#' + cname).data("info")["tte_id"]
                },
                asynchronous:true,
                evalScripts:true,
                method:'get',
                onComplete:function(resp){
                    showStatus(resp.responseJSON,month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1));
                }
            });
        },
        hoverClass: "drop-hover"
    });
}

function searchBatches(){
    var searchField = j('#search').val();
    search_batches = {};
    batches = {};
    var myExp = new RegExp(searchField, 'i');
    if (searchField != ""){
        for (key in all_batches){
            if(all_batches[key].match(myExp)){
                search_batches[key] = all_batches[key];
            }
        }
        batches = search_batches;
        j('.alloc_box').html(drawBox());
    }
    else{
        batches = all_batches;
        j('.alloc_box').html(drawBox());
    }
}


function showStatus(respjson,date){
    var room=[];
    if (respjson.status == true){
        j('#' + cname).css("background-color","#ffe7e7");
        originalBg = j('#' + drag_element ).css("background-color","#ffe7e7");
        class_rooms.select(function(cr){
            if (cr.classroom.id == j('#' + drag_element ).attr('data')) room.push(cr.classroom.name);
        })
        if (j('#'+ cname + ' ' + '.subtooltip').children('#' + j('#' + drag_element ).attr("data")).length == 0){
            room.each(function(c){
                j('#'+ cname + ' ' + '.subtooltip').append("<div class='room_name'" + "id=" + j('#' + drag_element ).attr("data") + ">" + "<span id='rname'" + c + "</span" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>")
            })
        }
    }

    if (respjson.status == false) {
        j('.sub').droppable('option', 'disabled', true);
        j('.alloc_box').addClass("transparency");
        var warning = document.createElement('div').addClassName("warning");
        j('.allocations').append(warning);
        var warning_msg = document.createElement('div').addClassName("warning_msg");
        var msg = "";
        respjson.msg.each(function(m){
            msg = msg +"<li>" + m + "</li>";
        })
        j(warning_msg).append(msg);
        j('.warning').append(warning_msg);
        var buttons = document.createElement('div').addClassName("confirm_buttons");
        j(warning).append(buttons);
        j(j('.warning_msg li').last()).css("list-style","none")
        j(j('.warning_msg li').last()).css("font-weight","normal")
        var continue_btn = "<button type='button' class ='continue_btn'>" + continue_text + "</button>"
        var cancel_btn = "<button type='button' class ='cancel_btn'>" + cancel_text + "</button>"
        j(buttons).append(continue_btn);
        j(buttons).append(cancel_btn);
        j('.continue_btn').click(function(){
            j('.warning').hide();
            j('.alloc_box').removeClass("transparency");
            j('#' + cname).css("background-color","#ffe7e7");
            j.get('/classroom_allocations/override_allocations',{
                date: date,
                alloc_type: allocation_type,
                status: respjson.status,
                classroom: respjson.classroom,
                timetable_entry: respjson.timetable_entry,
                allocation: respjson.allocation,
                subject: respjson.subject
            })
            class_rooms.select(function(cr){
                if (cr.classroom.id == j('#' + drag_element ).attr('data')) room.push(cr.classroom.name);
            })
            if (j('#'+ cname + ' ' + '.subtooltip').children('#' + j('#' + drag_element ).attr("data")).length == 0){
                room.each(function(c){
                    j('#'+ cname + ' ' + '.subtooltip').append("<div class='room_name'" + "id=" + j('#' + drag_element ).attr("data") + ">" + "<span id='rname'>" + c + "</span>" + "<div id = 'delete_room_link'><a onclick = 'removeRoom(this);'>x</a></div>"+ "</div>")
                })
            }
        });
        j('.cancel_btn').click(function(){
            j('.warning').hide();
            j('.alloc_box').removeClass("transparency");
        });
        j('.sub').droppable('option', 'disabled', false);
        if (respjson.flag == false) {
            j('.continue_btn').hide();
            j('.cancel_btn').css({
                "background-color":"#00628f",
                "color":"white"
            });
        }
    }
}

function removeRoom(ele){
    parent = j(ele).parents('.sub');
    val = j(ele).parents('.sub').data();
    j('.sub').droppable('option', 'disabled', true);
    j('.alloc_box').addClass("transparency");
    var warning = document.createElement('div').addClassName("warning");
    j('.allocations').append(warning);
    var warning_msg = document.createElement('div').addClassName("warning_msg");
    j(warning_msg).text(delete_allocation);
    j(warning).append(warning_msg);
    var buttons = document.createElement('div').addClassName("confirm_buttons");
    j(warning).append(buttons);
    var continue_btn = "<button type='button' class ='continue_btn'>" + continue_text + "</button>"
    var cancel_btn = "<button type='button' class ='cancel_btn'>" + cancel_text + "</button>"
    j(buttons).append(continue_btn);
    j(buttons).append(cancel_btn);

    j('.continue_btn').click(function(){
        j('.warning').hide();
        j('.alloc_box').removeClass("transparency");
        j('#' + cname).css("background-color","#ffe7e7");
        j('#' + drag_element ).css("background-color","#ffe7e7");
        var r_id = j(ele).parents('.room_name').attr("id");
        j.get('/classroom_allocations/delete_allocation',{
            tte_id: val.info.tte_id ,
            batch_id: val.info.batch_id,
            emp_id: val.info.emp_id,
            sub_id: val.info.sub_id,
            weekday_id: val.info.weekdayid,
            class_timing_id: val.info.class_timing_id,
            alloc_type: allocation_type,
            date: month_year + '-' + String(parseInt(j('.active_day').attr("id")) + 1),
            tt_id: selected_tt,
            room_id: r_id
        });

        j('.sub').droppable('option', 'disabled', false);
        j(j(ele).parents('.room_name')).remove();

        if(j(parent).children().children('.room_name').length == 0){
            j(parent).css("background-color","white");
            j('#' + cname).css("background-color","white");
        }

        ele.remove();



    });

    j('.cancel_btn').click(function(){
        j('.warning').hide();
        j('.alloc_box').removeClass("transparency");
        j('.sub').droppable('option', 'disabled', false);
    });
}