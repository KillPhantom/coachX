"""
日志工具模块
"""
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def info(message: str):
    """记录信息日志"""
    logger.info(message)

def error(message: str, error: Exception = None):
    """记录错误日志"""
    if error:
        logger.error(f'{message}: {str(error)}')
    else:
        logger.error(message)

def warning(message: str):
    """记录警告日志"""
    logger.warning(message)

