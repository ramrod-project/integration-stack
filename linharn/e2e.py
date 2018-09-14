from multiprocessing import Process
from os import environ
from time import sleep

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
    client_thread = Process(target=control_loop, args=("C_127.0.0.1_1",))
    client_thread.start()
    yield client_thread
    client_thread.terminate()

@fixture(scope="module")
def chrome_browser():
    # Connect to the Selenium server remove webdriver (Chrome)
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
    # Connect to the Selenium server remove webdriver (Firefox)
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

    firefox_browser.find_element_by_id('location_num').send_keys('127.0.0.2')

    submit = firefox_browser.find_element_by_id('add_target_submit')
    submit.click()

def test_instantiate_chrome(linharn_client, chrome_browser):
    """Test something...
    """
    # Add a target

    add_tgt = chrome_browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = chrome_browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    chrome_browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = chrome_browser.find_element_by_id('add_target_submit')
    submit.click()
    
    # Add a job. Run job is a separate test case. Test both Firefox and Chrome.

def test_instantiate_addjob0(linharn_client, firefox_browser):
    """Test something...
    """
    # add job from plugin list
    tgt_name = firefox_browser.find_element_by_id('name_tag_id0').get_attribute('Harness')
    #tgt_name.click()

    tgt_ip = firefox_browser.find_element_by_id('address_tag_id0').get_attribute('127.0.0.2')

    add_job = firefox_browser.find_element_by_id('add_job_sc_id0')
    add_job.click()

    firefox_browser.implicitly_wait(10)

    plugin = firefox_browser.find_element_by_id('pluginid1').get_attribute('Harness:5000')

    addr = firefox_browser.find_element_by_id('addressid1').get_attribute('127.0.0.2')


# Run same test using Chrome

def test_instantiate_addjob1(linharn_client, chrome_browser):
    """Test something...
    """

    # add job from plugin list
    tgt_name = chrome_browser.find_element_by_id('name_tag_id1').get_attribute('Harness')
    #tgt_name.click()

    tgt_ip = chrome_browser.find_element_by_id('address_tag_id1').get_attribute('127.0.0.1')

    add_job = chrome_browser.find_element_by_id('add_job_sc_id1')
    add_job.click()

    chrome_browser.implicitly_wait(10)

    plugin = chrome_browser.find_element_by_id('pluginid1').get_attribute('Harness:5000')

    addr = chrome_browser.find_element_by_id('addressid1').get_attribute('127.0.0.1')
    
   # Add commands to existing job
# Using Firefox browser

def test_instantiate_addcmd0(linharn_client):
    """Test something...
    """

    # Connect to the Selenium server remote webdriver (Firefox)
    firefox_browser = Remote("http://localhost:4444/wd/hub", DesiredCapabilities.FIREFOX.copy())
    firefox_browser.implicitly_wait(20)

    # bring up the Harness command list
    tgt_name = firefox_browser.find_element_by_id('name_tag_id1')
    tgt_name.click()
    
    echo_msg = firefox_browser.find_element_by_id('acommandid4')
    echo_msg.click()

    echo_txt = firefox_browser.find_element_by_id('argumentid0').send_keys('test1234')

    cmd_btn = firefox_browser.find_element_by_id('add_command_to_job_id2')
    cmd_btn.click()

    cmd_box = firefox_browser.find_element_by_id('commandid1').get_attribute('echo (test1234)')

# run test w/ chrome browser

def test_instantiate_addcmd1(linharn_client):
    """Test something...
    """

    # Connect to the Selenium server remote webdriver (Chrome)
    chrome_browser = Remote("http://localhost:4445/wd/hub", DesiredCapabilities.CHROME.copy())
    chrome_browser.implicitly_wait(20)

    # bring up the Harness command list
    tgt_name = chrome_browser.find_element_by_id('name_tag_id1')
    tgt_name.click()
    
    echo_msg = chrome_browser.find_element_by_id('acommandid4')
    echo_msg.click()

    echo_txt = chrome_browser.find_element_by_id('argumentid0').send_keys('test1234')

    cmd_btn = chrome_browser.find_element_by_id('add_command_to_job_id2')
    cmd_btn.click()

    cmd_box = chrome_browser.find_element_by_id('commandid1').get_attribute('echo (test1234)')

