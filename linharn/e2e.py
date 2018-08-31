from pytest import fixture, raises
import selenium
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
    # exception testing
    with raises(Exception):
        raise Exception
    # assert stuff
    assert True