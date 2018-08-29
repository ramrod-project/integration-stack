""" PCP Selenium automated tests. """

import unittest
import time
from time import sleep
from selenium.webdriver import Firefox
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.keys import Keys
#from .test1 import helper_function_one
opts = Options()
opts.set_headless()
assert opts.headless  # Operating in headless mode
browser = Firefox(options=opts)
browser.get('http://frontend:8080')

""" Page element check, checks for existence of elements in all four widgets """

search_form = browser.find_element_by_id('searchNameHere_id')
if search_form == get.attribute('searchNameHere_id'):
	 pass
else:
    raise Exception("Search Box not found - Failed")
plugin_name = browser.find_element_by_id('target_box_contentid')
if plugin_name == get.attribute('target_box_contentid'):
	 pass
else:
    raise Exception("Target Box not found - Failed")
search_command = browser.find_element_by_id('searchCommandid')
if search_command == get.attribute('searchCommandid'):
	 pass
else:
    raise Exception("Command Search not found - Failed")
search_output = browser.find_element_by_id("output_tabs")
if search_output == get.attribute('output_tabs'):
	 pass
else:
    raise Exception("Job output not found - Failed")

""" Add a target, using the add target button on the left side of the homepage """

# Add plugin
tgt_page = browser.find_element_by_id("add_target_id")
tgt_page.click()
add_target = browser.find_element_by_id("plugin_name")
add_target.click()
add_target.send_keys("h")   #highlights Harness plugin
sleep(2)
add_target.send_keys(Keys.ENTER)   #press enter key to select Harness plugin
sleep(2)
ip_locate = browser.find_element_by_id("location_num")
ip_locate.send_keys("192.168.1.1")
tgt_port = browser.find_element_by_id("port_num")
tgt_port.send_keys("5000")
submit_btn = browser.find_element_by_id("add_target_submit")
submit_btn.click()
sleep(10)                     #give time to return to homepage


# After return to homepage, check if W1 has plugin loaded
name_tag = browser.find_element_by_id("name_tag_id1")
print(name_tag)
if name_tag == input.get_attribute("Harness"):
	pass
else:
    raise Exception("wrong field value")
# equal_to = browser.find_element_by_id("name_tag_id1")
# helper_function_one(name_tag, equal_to=equal_to, "wrong field value")

# Add job using pancake button
add_job = browser.find_element_by_id("add_job_sc_id1")
add_job.click()

job_one = browser.find_element_by_id("pluginid1")
if job_one == input.get_attribute("Harness:5000"):
	pass
else:
    raise Exception("job field blank")

job_host = browser.find_element_by_id("addressid1")
if job_host == input.get_attribute("192.168.1.1"):
	pass
else:
    raise Exception("Wrong or no IP")

# see if W4 is loaded
job_out = browser.find_element_by_id("updateid1")
if job_out == input.get_attribute("terminal1"):
    pass
else:
    raise Exception("Job didn't load")


# Add command
name_tag.click()                  #clicks plugin to open command list in W3
echo_fcn = browser.find_element_by_id("acommandid6")
echo_fcn.click()

echo_txt = browser.find_element_by_id("argumentid_0")
echo_txt.send_keys("Hello")

add_cmd = browser.find_element_by_id("add_command_to_job_id2")
add_cmd.click()

job_row = browser.find_element_by_id("jobrow1")
if job_row == driver.getPageSource().contains("Echo(Hello)"):
    pass
else:
	raise Exception("Command not loaded")
# Run job
exec_btn = browser.find_element_by_id("execute_button")
exec_btn.click()

sleep(5)

# check if job is running

job_out = driver.find_elements_by_id("update_spin1")





sleep(20)
