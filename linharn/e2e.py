from multiprocessing import Process

from pytest import fixture, raises
from selenium.webdriver import Remote
# from selenium.webdriver import ChromeOptions
from selenium.webdriver import DesiredCapabilities
from selenium.webdriver.common.keys import Keys

from .linharn import control_loop
# Run #1

@fixture(scope="function")
def linharn_client():
    """Generates and runs a Harness plugin thread
    connecting to 127.0.0.1:5000
    """
    client_thread = Process(target=control_loop, args=("C_127.0.0.1_1",))
    client_thread.start()
    yield client_thread
    client_thread.terminate()

def test_instantiate_firefox(linharn_client):
    """Test something...
    """
    # Connect to the Selenium server remote webdriver (Firefox)
    ff_browser = Remote("http://localhost:4444/wd/hub", DesiredCapabilities.FIREFOX.copy())
    ff_browser.implicitly_wait(20)
    
    ff_browser.get("http://frontend:8080")
    
    # Add a target

    add_tgt = firefox_browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = firefox_browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    ff_browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = ff_browser.find_element_by_id('add_target_submit')
    submit.click()

def test_instantiate_chrome(linharn_client):
    """Test something...
    """
    
    # Connect to the Selenium server remote webdriver (Chrome)
    ch_browser = Remote("http://localhost:4445/wd/hub", DesiredCapabilities.CHROME.copy())
    ch_browser.implicitly_wait(20)
    
    ch_browser.get("http://frontend:8080")
    
    # Add a target

    add_tgt = ch_browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = ch_browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    ch_browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = ch_browser.find_element_by_id('add_target_submit')
    submit.click()
    
    # Add a job. Run job is a separate test case. Test both Firefox and Chrome.

def test_instantiate_addjob0(linharn_client):
    """Test something...
    """
    
    # Connect to the Selenium server remote webdriver (Firefox)
    ff_browser = Remote("http://localhost:4444/wd/hub", DesiredCapabilities.FIREFOX.copy())
    ff_browser.implicitly_wait(20)
    
    ff_browser.get("http://frontend:8080")
    
    # add job from plugin list
    tgt_name = ff_browser.find_element_by_id('name_tag_id0').get_attribute('Harness')
    #tgt_name.click()

    tgt_ip = ff_browser.find_element_by_id('address_tag_id0').get_attribute('127.0.0.2')

    add_job = ff_browser.find_element_by_id('add_job_sc_id0')
    add_job.click()

    ff_browser.implicitly_wait(10)

    plugin = ff_browser.find_element_by_id('pluginid1').get_attribute('Harness:5000')

    addr = ff_browser.find_element_by_id('addressid1').get_attribute('127.0.0.2')


# Run same test using Chrome

def test_instantiate_addjob1(linharn_client):
    """Test something...
    """
    
    # Connect to the selenium server remote webdriver (Chrome)
    ch_browser = Remote("http://localhost:4445/wd/hub", DesiredCapabilities.CHROME.copy())
    ch_browser.implicitly_wait(20)
    
    ch_browsner.get("http://frontend:8080")

    # add job from plugin list
    tgt_name = ch_browser.find_element_by_id('name_tag_id1').get_attribute('Harness')
    tgt_name.click()

    tgt_ip = ch_browser.find_element_by_id('address_tag_id1').get_attribute('127.0.0.1')

    add_job = ch_browser.find_element_by_id('add_job_sc_id1')
    add_job.click()

    ch_browser.implicitly_wait(10)

    plugin = ch_browser.find_element_by_id('pluginid1').get_attribute('Harness:5000')

    addr = ch_browser.find_element_by_id('addressid1').get_attribute('127.0.0.1')

