"""
Tests for ${PROJECT_NAME}
"""

from __NAME__.main import main


def test_main(capsys):
    """Test main function"""
    main()
    captured = capsys.readouterr()
    assert "Hello from ${PROJECT_NAME}!" in captured.out
    assert "Python project template" in captured.out
