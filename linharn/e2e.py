from pytest import fixture, raises
from selenium.webdriver import Firefox
from selenium.webdriver.firefox.options import Options
from selenium.webdriver.common.keys import Keys
import multiprocessing

from .linharn import control_loop

@fixture(scope="function")
def linharn_client():
    """Generates and runs a Harness plugin thread
    connecting to 127.0.0.1:5000
    """
    client_thread = multiprocessing.Process(target=control_loop)
    client_thread.start()
    yield client_thread
    client_thread.terminate()

def test_instantiate(linharn_client):
    """Test something...
    """

    opts = Options()
    opts.set_headless()
    assert opts.headless  # Operating in headless mode
    browser = Firefox(Options=opts)
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

    tgt_ip - browser.find_element_by_id('location_num').send_keys('127.0.0.1')

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
