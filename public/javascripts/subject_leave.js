var students, dates, leaves, holidays, batch, today, req, subject_id, translated, datearr;
var nameTdElem=new Element('td',{
    'class':'td-name'
});
var rowElem = new Element('tr',{
    'class':'tr-odd'
});
var absentElem = new Element('a',{
    'class':'absent themed_text',
    'id':''
});
var presentElem = new Element('a',{
    'class':'present',
    'id':'',
    'date':''
});
var cellElem = new Element('td',{
    'class':'td-mark'
});

function getjson(val){
    date_today = $('time_zone').value
    Element.show('loader')
    if (val){
        new Ajax.Request('/attendances/subject_wise_register.json',{
            parameters:'batch_id='+$('batch_id').value+'&subject_id='+val,
            asynchronous:true,
            evalScripts:true,
            method:'get',
            onComplete:function(resp){
                registerBuilder(resp.responseJSON);
                rebind();
                Element.hide('loader')
            }
        });
    }else
    {
        j("#register").children().hide();
        rebind();
        Element.hide('loader')
    }
}
function changeMonth(){
    Element.show('loader');
    new Ajax.Request('/attendances/subject_wise_register.json',{
        parameters:'batch_id='+this.getAttribute('batch_id')+'&next='+this.getAttribute('next')+'&subject_id='+$('subject_id').value,
        asynchronous:true,
        evalScripts:true,
        method:'get',
        onComplete:function(resp){
            registerBuilder(resp.responseJSON);
            rebind();
            Element.hide('loader')
        }
    });

}

function registerBuilder(respjson){
    dates = respjson.dates;
    students = respjson.students;
    leaves = respjson.leaves;
    translated=respjson.translated;
    //    holidays = respjson.holidays;
    today = respjson.today;
    batch = respjson.batch.batch;
    subject_id = $('subject_id').value;
    datearr = keys(dates).sort();

    //
    var dates_present=dateCheck();
    var header = drawHeader();
    var box = drawBox();
    var attChk = drawCheckbox();
    var flash_box= drawFlashBox();
    if (dates_present){
        $('register').update(attChk);
        $('register').appendChild(header);
    }
    else{
        $('register').update(header);
    }
    if (!dates_present){
        $('register').appendChild(flash_box);
    }
    else{
        $('register').appendChild(box);
        var tbl = $('register-table').down('tbody');
        students.each(function(student){
            tbl.appendChild(makeRow(student.student));
        });
        $$('.quick-attendance-div').invoke('observe','mouseover',showHelp)
        $$('.quick-attendance-div').invoke('observe','mouseout',hideHelp)
        $$('.attendance-label').invoke('observe','click',toggleMode)
    }
}
function dateCheck(){
    var date_check=false
    for(var i=0;i<datearr.length;i++){
        if(dates[datearr[i]] != null){
            dates[datearr[i]].each(function(e){
                date_check=true
            });
        }
    }
    return date_check
}
function toggleMode(){
    if($('quick-attendance-check').checked == false){
        $('quick-attendance-check').checked = true;
    }
    else{
        $('quick-attendance-check').checked = false;
    }
}
function showHelp(){
    $('quick_attendance').setStyle({
        height: '70px',
        width: '272px'
    });
    $('helper_tooltip').show();
}
function hideHelp(){
    $('quick_attendance').setStyle({
        height: 'auto',
        width: 'auto'
    });
    $('helper_tooltip').hide();
}
function drawCheckbox(){
    var newdiv = new Element('div',{
        'class':'quick-attendance-div',
        'id':'quick_attendance'
    }).addClassName('quick-attendance-div');
    var helperdiv = new Element('div',{
        'id':'helper_tooltip',
        'style':'display:none'
    }).addClassName('helper_info');
    helperdiv.update(translated['subjectwise_quick_attendance_explanation']);
    var chkbox=new Element('input',{
        'type':'checkbox',
        'id':'quick-attendance-check',
        'checked':false
    });
    var attendancelabel=new Element('label',{
        'class':'attendance-label'
    }).addClassName('attendance-label');
    attendancelabel.update(translated['rapid_attendance']);
    newdiv.update(attendancelabel);
    newdiv.appendChild(chkbox);
    newdiv.appendChild(helperdiv);
    return newdiv;
}
function drawFlashBox(){
    var box= new Element('div',{
        'class':'flash_msg'
    });
    box.textContent=translated['no_timetable_entries']
    return box
}
function drawHeader(){
    var header = new Element('div',{
        'class':'header'
    });
    var next = new Element('div',{
        'class':'next'
    });
    var nextln = new Element('a',{
        'class':'goto',
        'batch_id':batch.id,
        'next':Date.parse(today).add({
            month:1
        })
    }).update("►");
    var prev = new Element('div',{
        'class':'prev'
    });
    var prevln = new Element('a',{
        'class':'goto',
        'batch_id':batch.id,
        'next':Date.parse(today).add({
            month:-1
        })
    }).update("◄");
    var month = new Element('div',{
        'class':'month'
    }).update(translated[Date.parse(today).toString("MMMM")]+" "+Date.parse(today).toString("yyyy"));
    var extender = new Element('div',{
        'class':'extender'
    });
    prev.update(prevln);
    next.update(nextln);
    if((new Date(batch.start_date)).clearTime() < (Date.parse(today).moveToFirstDayOfMonth()).clearTime()) header.update(prev);
    header.appendChild(month);
    if((new Date(batch.end_date)).clearTime() > (Date.parse(today).moveToLastDayOfMonth()).clearTime()) header.appendChild(next);
    header.appendChild(extender);

    return header;

}
function drawBox(){
    var box = new Element('div',{
        'class':'box-1'
    });
    var tbl = new Element('table',{
        'id':'register-table'
    });
    var tblbody = new Element('tbody');
    var headrow = new Element('tr',{
        'class':'tr-head'
    });
    var nameTd = new Element('td',{
        'class':'head-td-name'
    }).update(translated['student']);

    var dateTd = new Element('td',{
        'class':'head-td-date'
    });
    var dtDiv1 = new Element('div',{
        'class':'day'
    });
    var dtDiv2 = new Element('div',{
        'class':'date'
    });
    var dtd, dtdiv1, dtdiv2, ndate, tdate;
    tdate = Date.parse(date_today);
    headrow.update(nameTd);    
    for(var i=0;i<datearr.length;i++){
        if(dates[datearr[i]] != null){
            dates[datearr[i]].each(function(e){
                ndate = Date.parse(datearr[i]);
                dtd = dateTd.cloneNode(true);
                dtdiv1 = dtDiv1.cloneNode(true);
                dtdiv2 = dtDiv2.cloneNode(true);
                //        if(holidays.include(dt))dtdiv1.addClassName('holiday');
                dtdiv1.update(translated[ndate.toString("ddd")]);
                dtdiv2.update(ndate.toString("dd"));
                if(tdate.equals(ndate))dtd.addClassName('active');
                dtd.update(dtdiv1);
                dtd.appendChild(dtdiv2);
                headrow.appendChild(dtd);
            });
        }
    }
    tblbody.update(headrow);
    tbl.update(tblbody);
    box.update(tbl)
    return box;
}
function makeRow(student){
    var nameTd=nameTdElem.cloneNode(true);
    var rowEl =rowElem.cloneNode(true);
    rowEl.update(nameTd.update(student.name));
    for(var i=0;i<datearr.length;i++){
        if(dates[datearr[i]] != null){
            dates[datearr[i]].each(function(e){
                rowEl.appendChild(makeCell(student,datearr[i],e));
            });
        }
    }
    return rowEl;
}
var cn = 0;
function makeCell(student,dt,el){
    var cellEl = cellElem.cloneNode(true);
    cellEl.id = 'student-'+student.id+'-date-'+d(dt)+'-timing-'+el.timetable_entry.class_timing_id
    var ndate, tdate,adm_date;
    adm_date=student.admission_date;
    tdate = Date.parse(date_today);
    ndate = Date.parse(dt);
    if(tdate.equals(ndate))
        cellEl.addClassName('active');
    if(leaves[student.id][dt]== null|| leaves[student.id][dt][el.timetable_entry.class_timing_id] == null){
        if(ndate <= tdate){
            var present = presentElem.cloneNode(true);
            present.setAttribute('date', dt);
            present.setAttribute('subject_id', dt);
            present.setAttribute('tt_entry', el.timetable_entry.id);
            present.id=student.id;
            present.setAttribute('admsn_date',adm_date)
            present.update("O");
        }
        cellEl.update(present);
    }
    else{
        if(ndate <= tdate){
            var absent = absentElem.cloneNode(true);
            absent.id=leaves[student.id][dt][el.timetable_entry.class_timing_id];
            absent.update("X");
        }
        cellEl.update(absent);
    }
    return(cellEl);
}

function d(dt){
    var dtar = dt.split("-");
    dt = dtar[2]+'-'+dtar[1]+'-'+dtar[0]
    return dt;
}
function cellHover(){
    var cIndex = this.cellIndex;
    var rIndex = this.up().rowIndex;
    var tbl = this.up(1);
    var dt = getDate(rIndex,cIndex,tbl);
    var name = getName(rIndex,cIndex,tbl);
    var descEl = makeHoverEl(dt,name);
    if(this.down('.date') == null) this.appendChild(descEl);
}
function getDate(row,col,tbl){
    var el = tbl.children[0].children[col];
    return({
        'day':el.down('.day').innerHTML,
        'date':el.down('.date').innerHTML
    })
}
function getName(row,col,tbl){
    var el = tbl.children[row].children[0];
    return(el.innerHTML);
}
function makeHoverEl(dt,name){
    var maindiv = new Element('div',{
        'class':'date'
    });
    var spanel =  new Element('span',{
        'class':'themed_text'
    });
    var secdiv = new Element('div');
    secdiv.update(name);
    spanel.update(dt.day+" "+dt.date);
    spanel.appendChild(secdiv);
    maindiv.update(spanel);
    return(maindiv);
}

function rebind(){
    $$('.absent').invoke('observe','click',edit)
    $$('.present').invoke('observe','click',add)
    $$('.td-mark').invoke('observe','mouseover',cellHover)
    $$('.goto').invoke('observe','click',changeMonth)
}
function edit(){
    new Ajax.Request('/attendances/'+this.id+'/edit',
    {
        asynchronous:true,
        evalScripts:true,
        method:'get'
    }
    )
}
function add(){
    if($('quick-attendance-check').checked == false){
        new Ajax.Request('/attendances/new',
        {
            parameters:'id='+this.id+'&date='+this.getAttribute('date')+'&timetable_entry='+this.getAttribute('tt_entry')+'&subject_id='+subject_id,
            asynchronous:true,
            evalScripts:true,
            method:'get'
        }
        )
    }
    else{
        if(this.getAttribute('admsn_date') <= this.getAttribute('date'))
        {
            new Ajax.Request('/attendances/quick_attendance',
            {
                parameters:'id='+this.id+'&date='+this.getAttribute('date')+'&timetable_entry='+this.getAttribute('tt_entry')+'&subject_id='+subject_id,
                asynchronous:true,
                evalScripts:true,
                method:'get'
            }
            )
        }
        else
        {
            alert(translated['attendance_before_the_date_of_admission_is_invalid']);
        }
    }
}
document.observe("dom:loaded", function() {
    rebind();
});

keys=function(obj){
    var arr=[];
    for(var dt in obj){
        arr.push(dt);
    }
    return(arr);
}