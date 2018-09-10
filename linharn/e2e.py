import multiprocessing

from pytest import fixture, raises
from selenium.webdriver import Remote
from selenium.webdriver import DesiredCapabilities
from selenium.webdriver.common.keys import Keys

from .linharn import control_loop


@fixture(scope="function")
def linharn_client():
    """Generates and runs a Harness plugin thread
    connecting to 127.0.0.1:5000
    """
    client_thread = multiprocessing.Process(target=control_loop, args=("C_127.0.0.1_1",))
    client_thread.start()
    yield client_thread
    client_thread.terminate()

def test_instantiate_firefox(linharn_client):
    """Test something...
    """

    # Connect to the Selenium server remove webdriver (Firefox)
    ff_browser = Remote("http://localhost:4444/wd/hub", DesiredCapabilities.FIREFOX.copy())
    ff_browser.implicitly_wait(20)

    ff_browser.get("http://frontend:8080")

    # Add a target

    add_tgt = ff_browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = ff_browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    ff_browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = ff_browser.find_element_by_id('add_target_submit')
    submit.click()

def test_instantiate_chrome(linharn_client):
    """Test something...
    """

    # Connect to the Selenium server remove webdriver (Firefox)
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