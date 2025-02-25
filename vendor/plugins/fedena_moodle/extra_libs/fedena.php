<?php

require_once('config.php');

if ($_REQUEST['action'] == "Ping"){
	echo Ping();
}
else if ($_REQUEST['action'] == "CreateAccount"){
	$act = CreateAccount($params);
	echo $act[1];die();
}
else if ($_REQUEST['action'] == "UpdateAccount"){
	$act = UpdateAccount($_REQUEST['oldusername']);
	echo $act[1];die();
}
else if ($_REQUEST['action'] == "UpdateAccountPassword"){
	$act = UpdateAccountPassword($_REQUEST['username']);
	echo $act[1];die();
}
else if ($_REQUEST['action'] == "CreateSubject"){
	$act = CreateSubject($params);
	echo $act[1];die();
}
else if ($_REQUEST['action'] == "UpdateSubject"){
	if($_REQUEST['delete'] == '1'){
		$act = DeleteSubject($_REQUEST['course_category_id']);
	}
	else{
		$act = UpdateSubject($_REQUEST['course_category_id']);
	}
	echo $act[1];die();
}
else if ($_REQUEST['action'] == "CreateCourse"){
	$act = CreateCourse($params);
	echo $act[1];die();
}
else if ($_REQUEST['action'] == "UpdateCourse"){
    $act = UpdateCourse($_REQUEST['course_id']);
	echo $act[1];die();
}
else{
	echo "Invalid request"; die();
}

function Ping(){
	return "Success";
}



function CreateAccount($params){
	global $DB;
	$countries = get_string_manager()->get_list_of_countries();
    /* check to see if input parameter 0 holds all account information */
    if (is_array($params[0])) {
        $new_user = $params[0];

        // make sure the user does not already exist
        if (!($DB->get_record("user", array("username"=>$new_user['username'])))) {

            $retval = insert_record("user", $new_user);

            if (!$retval) // if insert failed, return fail
                return array(FALSE, "fail:insert record failed");
            else
                return array(TRUE, "success");

        } else { // user already exists; return fail
            return array(FALSE, "fail:user already exists");
        }
    }

    /* otherwise account information is being sent as individual parameters */

    $user_name = $_REQUEST['username'];
    // make sure the user does not already exist
    if (!($DB->get_record("user", array("username"=>$user_name)))) { 
		#Whitelist params	
        $new_user['username'] = urldecode($_REQUEST['username']);
        $new_user['firstname'] = urldecode($_REQUEST['firstname']);
        $new_user['lastname'] = urldecode($_REQUEST['lastname']);
        $new_user['email'] = urldecode($_REQUEST['email']);
        $new_user['city'] = urldecode($_REQUEST['city']);
        $new_user['country'] = array_search(urldecode($_REQUEST['country']),$countries);
        $new_user['idnumber'] = urldecode($_REQUEST['idnumber']);
        $new_user['phone1'] = urldecode($_REQUEST['phone1']);
        $new_user['phone2'] = urldecode($_REQUEST['phone2']);
        $new_user['address'] = urldecode($_REQUEST['address']);
        $new_user['timemodified'] = time();
        $new_user['password'] = hash_internal_user_password($_REQUEST['password']);
        $new_user['confirmed'] = 1;
        $new_user['auth'] = "manual";
        $new_user['mnethostid']= 1;
        $new_user['maildisplay'] = 2;
        $new_user['mailformat'] = 1;
        $new_user['autosubscribe'] = 1;
        $new_user['htmleditor'] = 1;
        $new_user['lang'] = "en";
        $new_user['timezone'] = 99;
        
        
        $retval = $DB->insert_record("user", $new_user);

        if (!$retval)
            return array(FALSE, "fail:insert_record");
        else
            return array(TRUE, "success");
			
    } else { // user already exists; return fail	
        return array(FALSE, "fail:user already exists");
    }
}
function UpdateAccount($oldusername){
	global $DB;
	$countries = get_string_manager()->get_list_of_countries();
    //$m_user = (object)$params[0];
	$user = $DB->get_record("user", array("username"=>$oldusername));
	if ($user) {
	$userid = $user->id;
	    $fedena_user['username'] = urldecode($_REQUEST['username']);
        $fedena_user['firstname'] = urldecode($_REQUEST['firstname']);
        $fedena_user['lastname'] = urldecode($_REQUEST['lastname']);
        $fedena_user['email'] = urldecode($_REQUEST['email']);
        $fedena_user['city'] = urldecode($_REQUEST['city']);
        $fedena_user['country'] = array_search($_REQUEST['country'],$countries);
        $fedena_user['idnumber'] = urldecode($_REQUEST['idnumber']);
        $fedena_user['phone1'] = urldecode($_REQUEST['phone1']);
        $fedena_user['phone2'] = urldecode($_REQUEST['phone2']);
        $fedena_user['address'] = urldecode($_REQUEST['address']);
        $fedena_user['timemodified'] = time();
        //$fedena_user['password'] = hash_internal_user_password($_REQUEST['password']);
        $fedena_user['id'] = $userid;

	
		if (!$DB->update_record('user', $fedena_user)) {
			return array(FALSE, "Update failed!".print_r($params));
		}
    return array(TRUE, "success");
	}
	else{
        $new_user['username'] = urldecode($_REQUEST['username']);
        $new_user['firstname'] = urldecode($_REQUEST['firstname']);
        $new_user['lastname'] = urldecode($_REQUEST['lastname']);
        $new_user['email'] = urldecode($_REQUEST['email']);
        $new_user['city'] = urldecode($_REQUEST['city']);
        $new_user['country'] = array_search(urldecode($_REQUEST['country']),$countries);
        $new_user['idnumber'] = urldecode($_REQUEST['idnumber']);
        $new_user['phone1'] = urldecode($_REQUEST['phone1']);
        $new_user['phone2'] = urldecode($_REQUEST['phone2']);
        $new_user['address'] = urldecode($_REQUEST['address']);
        $new_user['timemodified'] = time();
        $new_user['password'] = hash_internal_user_password($_REQUEST['username'].'123');
        $new_user['confirmed'] = 1;
        $new_user['auth'] = "manual";
        $new_user['mnethostid']= 1;
        $new_user['maildisplay'] = 2;
        $new_user['mailformat'] = 1;
        $new_user['autosubscribe'] = 1;
        $new_user['htmleditor'] = 1;
        $new_user['lang'] = "en";
        $new_user['timezone'] = 99;
        
        $retval = $DB->insert_record("user", $new_user);

		if (!$retval)
			return array(FALSE, "user not found! failed in creating new user".print_r($params));
        else
            return array(TRUE, "user not found! New user created.");
	}
}

function UpdateAccountPassword($username){
	global $DB;
	$countries = get_string_manager()->get_list_of_countries();
	$user = $DB->get_record("user", array("username"=>$username));
	if ($user) {
        $fedena_user['timemodified'] = time();
        $fedena_user['password'] = hash_internal_user_password($_REQUEST['password']);
        $fedena_user['id'] = $user->id;

    if (!$DB->update_record('user', $fedena_user)) {
        return array(FALSE, "Update failed!".print_r($params));
    }
    return array(TRUE, "success");
	}
	else{
		return array(FALSE, "user not found!".print_r($params));
	}
}

?>
