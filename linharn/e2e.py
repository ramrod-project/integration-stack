import multiprocessing

from pytest import fixture, raises
from pyvirtualdisplay import Display
from selenium.webdriver import Chrome
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

def test_instantiate(linharn_client):
    """Test something...
    """

    # Start virtual display
    display = Display(visible=0, size=(1920, 1080))
    display.start()

    # Start firefox browser using the virtual display
    browser = Chrome()
    browser.implicitly_wait(20)

    browser.get("http://frontend:8080")

    # Add a target

    add_tgt = browser.find_element_by_id('add_target_id')
    add_tgt.click()

    plgn = browser.find_element_by_id('service_name')
    plgn.click()
    plgn.send_keys('h')
    plgn.send_keys(Keys.ENTER)

    browser.find_element_by_id('location_num').send_keys('127.0.0.1')

    submit = browser.find_element_by_id('add_target_submit')
    submit.click()