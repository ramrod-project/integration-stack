from multiprocessing import Process
from os import environ
from time import sleep, time

from pytest import fixture, raises
import rethinkdb as r
from selenium.webdriver import Chrome, Firefox, Remote
from selenium.webdriver import ChromeOptions
from selenium.webdriver import DesiredCapabilities
from selenium.webdriver.common.keys import Keys

from .linharn import control_loop

TARGET_TABLE = r.db("Brain").table("Targets")
OUTPUT_TABLE = r.db("Brain").table("Outputs")
JOBS_TABLE = r.db("Brain").table("Jobs")

TABLES = [TARGET_TABLE, OUTPUT_TABLE, JOBS_TABLE]

# Fixture will delete all jobs, targets, and outputs
# before a test session from database.
@fixture(scope="session", autouse=True)
def clear_dbs():
    conn = r.connect("frontend")
    for table in TABLES:
        table.delete().run(conn)
    sleep(1)

@fixture(scope="function")
def linharn_client():
    """Generates and runs a Harness plugin thread
    connecting to 127.0.0.1:5000
    """
    r.connect("frontend").repl()
    client_thread = Process(target=control_loop, args=("C_127.0.0.1_1",))
    client_thread.start()
    yield client_thread
    client_thread.terminate()

@fixture(scope="module")
def chrome_browser():
    # Connect to the Selenium server remote webdriver (Chrome)
    no_headless = environ.get("NO_HEADLESS", "")
    if no_headless == "TRUE":
        browser = Firefox()
    else:
        browser = Remote("http://localhost:4445/wd/hub", DesiredCapabilities.CHROME.copy())
    browser.implicitly_wait(20)
    browser.get("http://frontend:8080")
    yield browser
    browser.close()

@fixture(scope="module")
def firefox_browser():
    # Connect to the Selenium server remote webdriver (Firefox)
    no_headless = environ.get("NO_HEADLESS", "")
    if no_headless == "TRUE":
        browser = Firefox()
    else:
        browser = Remote("http://localhost:4444/wd/hub", DesiredCapabilities.FIREFOX.copy())
    browser.implicitly_wait(20)
    browser.get("http://frontend:8080")
    yield browser
    browser.close()

def test_instantiate_firefox(linharn_client, firefox_browser):
    """Test something...
    """

    # Add a target

    add_tgt = firefox_browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = firefox_browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    firefox_browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = firefox_browser.find_element_by_id('add_target_submit')
    submit.click()


def test_instantiate_addjob0(linharn_client, firefox_browser):
 
    tgt_name = firefox_browser.find_element_by_id('name_tag_id0')
    tgt_name.click()
    tgt_name.get_attribute('Harness')

    tgt_ip = firefox_browser.find_element_by_id('address_tag_id0').get_attribute('127.0.0.1')

    add_job = firefox_browser.find_element_by_id('add_job_sc_id0')
    add_job.click()

    plugin = firefox_browser.find_element_by_id('pluginid1').get_attribute('Harness:5000')

    addr = firefox_browser.find_element_by_id('addressid1').get_attribute('127.0.0.1')


    # Add commands to existing job
# Using Firefox browser

def test_instantiate_addcmd0(linharn_client, firefox_browser):
    """ Adds command to job
    """
    tgt_name = firefox_browser.find_element_by_id('name_tag_id0')
    tgt_name.click()
    
    cmd_name = firefox_browser.find_element_by_id('acommandid4')
    cmd_name.click()

    cmd_txt = firefox_browser.find_element_by_id('argumentid_0').send_keys('test1234')

    cmd_btn = firefox_browser.find_element_by_id('add_command_to_job_id2')
    cmd_btn.click()

    cmd_box = firefox_browser.find_element_by_id('commandid1').get_attribute('test1234')
	
def test_instantiate_runjob0(linharn_client, firefox_browser):
    """ Starts job. 
    """

    exec_btn = firefox_browser.find_element_by_id('execute_button')
    exec_btn.click()

def test_instantiate_chkjob0(linharn_client, firefox_browser):
    """Check to see if job was successful 
    """
    done = False
    res = None
    start = time()
    while time() - start < 30:
        c = JOBS_TABLE.run()
        for d in c:
            res = d
        if res and res["Status"] == "Done":
            done = True
            break
        sleep(1)
    print(res)
    assert done

#------------------------------------------------------------------------------    
# Begin Chrome tests
#------------------------------------------------------------------------------
""""    
def test_instantiate_chrome(linharn_client, chrome_browser):

    add_tgt = chrome_browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = chrome_browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    chrome_browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = chrome_browser.find_element_by_id('add_target_submit')
    submit.click()
    
def test_instantiate_addjob1(linharn_client, chrome_browser):

    tgt_name = chrome_browser.find_element_by_id('name_tag_id1')
    tgt_name.click()
    tgt_name.get_attribute('Harness')

    tgt_ip = chrome_browser.find_element_by_id('address_tag_id1').get_attribute('127.0.0.1')

    add_job = chrome_browser.find_element_by_id('add_job_sc_id1')
    add_job.click()

    plugin = chrome_browser.find_element_by_id('pluginid1').get_attribute('Harness:5000')

    addr = chrome_browser.find_element_by_id('addressid1').get_attribute('127.0.0.1')
    
        # Add a command to existing job

def test_instantiate_addcmd1(linharn_client, chrome_browser):
    """ Adds a command
    """

    # bring up the Harness command list
    tgt_name = chrome_browser.find_element_by_id('name_tag_id1')
    tgt_name.click()
    
    cmd_name = chrome_browser.find_element_by_id('acommandid4')
    cmd_name.click()

    cmd_txt = chrome_browser.find_element_by_id('argumentid_0').send_keys('test1234')

    cmd_btn = chrome_browser.find_element_by_id('add_command_to_job_id2')
    cmd_btn.click()

    cmd_box = chrome_browser.find_element_by_id('commandid1').get_attribute('test1234')
	
def test_instantiate_runjob1(linharn_client, chrome_browser):
    """ Starts job.
    """

    exec_btn = chrome_browser.find_element_by_id('execute_button')
    exec_btn.click()

def test_instantiate_chkjob1(linharn_client, chrome_browser):
    """Check to see if job was successful 
    """
    done = False
    res = None
    start = time()
    while time() - start < 30:
        c = JOBS_TABLE.run()
        for d in c:
            res = d
        if res and res["Status"] == "Done":
            done = True
            break
        sleep(1)
    print(res)
    assert done
    
    """


