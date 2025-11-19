import logging

import logging_config

logging_config.setup_root_logger()


if __name__ == "__main__":
    logger = logging.getLogger()

    logger.debug("debug logging")
    logger.info("info logging")
    logger.warning("warning logging")
    logger.error("error logging")
    try:
        raise ValueError("some error")
    except:
        logger.exception("error")