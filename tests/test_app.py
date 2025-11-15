import pytest

def test_docker_file_exists():
    """Verifica que Dockerfile existe"""
    import os
    assert os.path.exists("Dockerfile"), "Dockerfile no encontrado"

def test_requirements_exists():
    """Verifica que requirements.txt existe"""
    import os
    assert os.path.exists("requirements.txt"), "requirements.txt no encontrado"

def test_project_structure():
    """Verifica estructura básica del proyecto"""
    import os
    assert os.path.exists(".github"), ".github carpeta no encontrada"
    assert os.path.exists(".github/workflows"), "workflows carpeta no encontrada"

def test_basic_math():
    """Test básico de matemática"""
    assert 1 + 1 == 2
    assert 5 > 3

def test_string_operation():
    """Test de strings"""
    text = "pcfactory"
    assert len(text) == 9
    assert text.startswith("pc")

def test_list_operations():
    """Test de listas"""
    items = [1, 2, 3, 4, 5]
    assert len(items) == 5
    assert sum(items) == 15
