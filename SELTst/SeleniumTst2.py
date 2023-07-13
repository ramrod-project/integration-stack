""" Selenium end-to-end test """

from selenium.webdriver import Firefox
from selenium.webdriver.common.keys import Keys

browser = Firefox()
browser.get("http://frontend:8080")

# test cases

add_tgt = browser.find_element_by_id('add_target_id')
add_tgt.click()

plgn = browser.find_element_by_id('plugin_name')
plgn.click()
plgn.send_keys('h')
plgn_opt = browser.find_element_by_id('1')
plgn_opt.click()
plgn.send_keys(Keys.ENTER)

tgt_ip - browser.find_element_by_id('location_num').send_keys(192.168.1.1')

tgt_port = browser.find_element_by_id('port_num')
tgt_port.send_keys('5000')
tgt_port.send_keys(Keys.ENTER)

tgt_name = browser.find_element_by_id('name_tag_id1')
tgt_name.click()

tgt_ip = browser.find_element_by_id('address_tag_id1')

add_job = browser.find_element_by_id('add_job_sc_id1')
add_job.click()

browser.implicitly_wait(10)

cmd_name = browser.find_element_by_id('acommandid6')
cmd_name.click()
