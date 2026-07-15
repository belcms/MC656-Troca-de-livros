"""
Testes de Particionamento em Classes de Equivalência
=====================================================

Entidades testadas:
  1. RegisterRequest  — validação de cadastro de usuário
  2. EditionPydantic  — validação de criação de edição de livro
  3. TradeAnnouncementPydantic — validação de criação de anúncio de troca

"""

from datetime import date, timedelta
import pytest
from pydantic import ValidationError


# ============================================================================
# Helpers: payloads-base com todos os campos válidos
# ============================================================================

def _valid_register_payload(**overrides) -> dict:
    """Retorna um dict com dados válidos para RegisterRequest.

    Qualquer campo pode ser sobrescrito para isolar o teste de um campo
    específico, mantendo todos os demais válidos.
    """
    data = {
        "full_name": "Maria Silva",
        "nickname": "maria",
        "email": "maria@example.com",
        "password": "segredo123",
        "birth_date": "2000-01-15",
        "cep": "13000-000",
    }
    data.update(overrides)
    return data


def _valid_edition_payload(**overrides) -> dict:
    """Retorna um dict com dados válidos para EditionPydantic.

    Usa os aliases esperados pelo schema (year, pages, bookId).
    """
    data = {
        "publisher": "Editora Teste",
        "year": 2020,
        "pages": 300,
        "language": "PT-br",
    }
    data.update(overrides)
    return data


def _valid_announcement_payload(**overrides) -> dict:
    """Retorna um dict com dados válidos para TradeAnnouncementPydantic.

    Usa os aliases esperados pelo schema (editionId, coverUrl, cep).
    """
    data = {
        "editionId": "some-edition-uuid",
        "condition": "New",
        "description": "Livro em ótimo estado",
        "coverUrl": "https://example.com/photo.jpg",
    }
    data.update(overrides)
    return data


# ============================================================================
# 1. RegisterRequest — Validação de Cadastro de Usuário
# ============================================================================
#
# Critérios de particionamento por campo:
#
# full_name (str, min_length=1, max_length=150, validator non_blank):
#   Válida: 1 ≤ len ≤ 150 e não é apenas espaços em branco
#   Inválida: string vazia, apenas espaços, >150 caracteres
#
# nickname (str, min_length=1, max_length=50, validator non_blank):
#   Válida: 1 ≤ len ≤ 150 e não é apenas espaços
#   Inválida: string vazia, apenas espaços, >50 caracteres
#
# email (EmailStr):
#   Válida: formato user@domínio.tld
#   Inválida: sem @, sem domínio, string vazia
#
# password (str, min_length=8, max_length=128):
#   Válida: 8 ≤ len ≤ 128
#   Inválida: <8 caracteres, >128 caracteres
#
# birth_date (date, validator past_birth_date):
#   Válida: data estritamente no passado
#   Inválida: data de hoje (>= today), data no futuro
#
# cep (str, validator valid_cep → regex \d{5}-?\d{3}):
#   Válida: 8 dígitos puros, 5 dígitos + hífen + 3 dígitos
#   Inválida: menos de 8 dígitos, mais de 8 dígitos, contém letras
# ============================================================================

class TestRegisterRequestEquivalencePartitioning:
    """Testes de particionamento para RegisterRequest (auth/schemas.py).

    Cada teste isola UM campo, mantendo todos os outros válidos,
    e verifica se o schema aceita (classe válida) ou rejeita (classe inválida).
    """

    # ---- full_name ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("Ana", "nome curto (limite inferior: 1+ char)"),
            ("A" * 150, "nome no limite máximo (150 chars)"),
            ("Maria da Silva", "nome com espaços internos"),
        ],
        ids=["nome_curto", "limite_maximo_150", "nome_com_espacos"],
    )
    def test_full_name_valid(self, value, description):
        """Classe VÁLIDA de full_name: strings de 1 a 150 chars não-brancos."""
        from app.domain.auth.schemas import RegisterRequest
        req = RegisterRequest(**_valid_register_payload(full_name=value))
        assert req.full_name == value.strip()

    @pytest.mark.parametrize(
        "value, description",
        [
            ("", "string vazia (abaixo do min_length)"),
            ("   ", "apenas espaços (falha no validator non_blank)"),
            ("A" * 151, "nome excede limite máximo (151 chars)"),
        ],
        ids=["vazio", "apenas_espacos", "excede_150_chars"],
    )
    def test_full_name_invalid(self, value, description):
        """Classe INVÁLIDA de full_name: vazio, branco ou >150."""
        from app.domain.auth.schemas import RegisterRequest
        with pytest.raises(ValidationError):
            RegisterRequest(**_valid_register_payload(full_name=value))

    # ---- nickname ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("m", "nickname de 1 caractere (limite inferior)"),
            ("N" * 50, "nickname no limite máximo (50 chars)"),
        ],
        ids=["1_char", "limite_maximo_50"],
    )
    def test_nickname_valid(self, value, description):
        """Classe VÁLIDA de nickname: 1 a 50 chars não-brancos."""
        from app.domain.auth.schemas import RegisterRequest
        req = RegisterRequest(**_valid_register_payload(nickname=value))
        assert req.nickname == value.strip()

    @pytest.mark.parametrize(
        "value, description",
        [
            ("", "string vazia"),
            ("   ", "apenas espaços"),
            ("N" * 51, "excede limite máximo (51 chars)"),
        ],
        ids=["vazio", "apenas_espacos", "excede_50_chars"],
    )
    def test_nickname_invalid(self, value, description):
        """Classe INVÁLIDA de nickname: vazio, branco ou >50."""
        from app.domain.auth.schemas import RegisterRequest
        with pytest.raises(ValidationError):
            RegisterRequest(**_valid_register_payload(nickname=value))

    # ---- email ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("user@domain.com", "formato padrão"),
            ("user.name+tag@sub.domain.org", "formato com subdomínio e tag"),
        ],
        ids=["padrao", "com_tag_e_subdominio"],
    )
    def test_email_valid(self, value, description):
        """Classe VÁLIDA de email: formato RFC 5322 aceito pelo EmailStr."""
        from app.domain.auth.schemas import RegisterRequest
        req = RegisterRequest(**_valid_register_payload(email=value))
        assert "@" in req.email

    @pytest.mark.parametrize(
        "value, description",
        [
            ("sem-arroba.com", "sem caractere @"),
            ("user@", "sem domínio após @"),
            ("", "string vazia"),
        ],
        ids=["sem_arroba", "sem_dominio", "vazio"],
    )
    def test_email_invalid(self, value, description):
        """Classe INVÁLIDA de email: formatos que violam a estrutura de e-mail."""
        from app.domain.auth.schemas import RegisterRequest
        with pytest.raises(ValidationError):
            RegisterRequest(**_valid_register_payload(email=value))

    # ---- password ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("12345678", "exatamente 8 chars (limite inferior)"),
            ("a" * 128, "exatamente 128 chars (limite superior)"),
            ("senha_segura_42!", "comprimento intermediário"),
        ],
        ids=["limite_inferior_8", "limite_superior_128", "intermediario"],
    )
    def test_password_valid(self, value, description):
        """Classe VÁLIDA de password: entre 8 e 128 caracteres."""
        from app.domain.auth.schemas import RegisterRequest
        req = RegisterRequest(**_valid_register_payload(password=value))
        assert req.password == value

    @pytest.mark.parametrize(
        "value, description",
        [
            ("1234567", "7 chars — abaixo do mínimo"),
            ("a" * 129, "129 chars — acima do máximo"),
        ],
        ids=["abaixo_minimo_7", "acima_maximo_129"],
    )
    def test_password_invalid(self, value, description):
        """Classe INVÁLIDA de password: fora do intervalo [8, 128]."""
        from app.domain.auth.schemas import RegisterRequest
        with pytest.raises(ValidationError):
            RegisterRequest(**_valid_register_payload(password=value))

    # ---- birth_date ----

    @pytest.mark.parametrize(
        "value, description",
        [
            (str(date.today() - timedelta(days=1)), "ontem (1 dia no passado)"),
            ("1990-06-15", "data distante no passado"),
        ],
        ids=["ontem", "passado_distante"],
    )
    def test_birth_date_valid(self, value, description):
        """Classe VÁLIDA de birth_date: qualquer data estritamente anterior a hoje."""
        from app.domain.auth.schemas import RegisterRequest
        req = RegisterRequest(**_valid_register_payload(birth_date=value))
        assert req.birth_date < date.today()

    @pytest.mark.parametrize(
        "value, description",
        [
            (str(date.today()), "hoje (>= today é rejeitado pelo validator)"),
            (str(date.today() + timedelta(days=30)), "30 dias no futuro"),
        ],
        ids=["hoje", "futuro"],
    )
    def test_birth_date_invalid(self, value, description):
        """Classe INVÁLIDA de birth_date: hoje ou qualquer data futura."""
        from app.domain.auth.schemas import RegisterRequest
        with pytest.raises(ValidationError):
            RegisterRequest(**_valid_register_payload(birth_date=value))

    # ---- cep ----

    @pytest.mark.parametrize(
        "value, expected_normalized, description",
        [
            ("13000000", "13000000", "8 dígitos sem hífen"),
            ("13000-000", "13000000", "com hífen (formato padrão brasileiro)"),
        ],
        ids=["sem_hifen", "com_hifen"],
    )
    def test_cep_valid(self, value, expected_normalized, description):
        """Classe VÁLIDA de cep: 8 dígitos puros ou no formato XXXXX-XXX."""
        from app.domain.auth.schemas import RegisterRequest
        req = RegisterRequest(**_valid_register_payload(cep=value))
        assert req.cep == expected_normalized

    @pytest.mark.parametrize(
        "value, description",
        [
            ("1300000", "7 dígitos — menos que o necessário"),
            ("130000001", "9 dígitos — mais que o necessário"),
            ("1300a000", "contém letra no meio"),
            ("abcdefgh", "apenas letras"),
        ],
        ids=["7_digitos", "9_digitos", "letra_no_meio", "apenas_letras"],
    )
    def test_cep_invalid(self, value, description):
        """Classe INVÁLIDA de cep: não bate com regex \\d{5}-?\\d{3}."""
        from app.domain.auth.schemas import RegisterRequest
        with pytest.raises(ValidationError):
            RegisterRequest(**_valid_register_payload(cep=value))


# ============================================================================
# 2. EditionPydantic — Validação de Criação de Edição de Livro
# ============================================================================
#
# Critérios de particionamento por campo:
#
# publisher (str, obrigatório):
#   Válida: qualquer string não-vazia
#   Inválida: campo ausente (é required)
#
# publish_year (int, alias "year", obrigatório):
#   Válida: inteiro (qualquer — o schema não limita o range)
#   Inválida: campo ausente, tipo não-inteiro (string)
#
# number_of_pages (int, alias "pages", obrigatório):
#   Válida: inteiro (qualquer)
#   Inválida: campo ausente, tipo não-inteiro (string)
#
# language (Language enum: "PT-br", "En", "Espanhol"):
#   Válida: qualquer valor pertencente ao enum
#   Inválida: valor fora do enum (ex: "Francês")
#
# cover_photo (Optional[str]):
#   Válida: string com URL, None (ausente)
#   (Não possui classe inválida — aceita qualquer string ou None)
# ============================================================================

class TestEditionPydanticEquivalencePartitioning:
    """Testes de particionamento para EditionPydantic (books/schemas.py).

    Cada teste isola UM campo, mantendo os demais válidos.
    """

    # ---- publisher ----

    def test_publisher_valid_string(self):
        """Classe VÁLIDA de publisher: string não-vazia."""
        from app.domain.books.schemas import EditionPydantic
        edition = EditionPydantic(**_valid_edition_payload(publisher="Companhia das Letras"))
        assert edition.publisher == "Companhia das Letras"

    def test_publisher_invalid_absent(self):
        """Classe INVÁLIDA de publisher: campo ausente (required)."""
        from app.domain.books.schemas import EditionPydantic
        payload = _valid_edition_payload()
        del payload["publisher"]
        with pytest.raises(ValidationError):
            EditionPydantic(**payload)

    # ---- publish_year (alias "year") ----

    @pytest.mark.parametrize(
        "value, description",
        [
            (2024, "ano contemporâneo (valor intermediário típico)"),
            (1450, "ano histórico — livro antigo (limite inferior razoável)"),
            (0, "ano zero — valor-limite extremo aceito pelo schema"),
        ],
        ids=["contemporaneo", "historico", "ano_zero"],
    )
    def test_publish_year_valid(self, value, description):
        """Classe VÁLIDA de publish_year: qualquer inteiro (schema sem restrição de range)."""
        from app.domain.books.schemas import EditionPydantic
        edition = EditionPydantic(**_valid_edition_payload(year=value))
        assert edition.publish_year == value

    @pytest.mark.parametrize(
        "value, description",
        [
            ("dois mil", "string não-numérica — tipo errado"),
        ],
        ids=["string_nao_numerica"],
    )
    def test_publish_year_invalid_type(self, value, description):
        """Classe INVÁLIDA de publish_year: tipo não-inteiro."""
        from app.domain.books.schemas import EditionPydantic
        with pytest.raises(ValidationError):
            EditionPydantic(**_valid_edition_payload(year=value))

    def test_publish_year_invalid_absent(self):
        """Classe INVÁLIDA de publish_year: campo ausente (required)."""
        from app.domain.books.schemas import EditionPydantic
        payload = _valid_edition_payload()
        del payload["year"]
        with pytest.raises(ValidationError):
            EditionPydantic(**payload)

    # ---- number_of_pages (alias "pages") ----

    @pytest.mark.parametrize(
        "value, description",
        [
            (1, "1 página — limite inferior razoável"),
            (500, "valor intermediário típico"),
        ],
        ids=["1_pagina", "intermediario"],
    )
    def test_pages_valid(self, value, description):
        """Classe VÁLIDA de number_of_pages: inteiro positivo."""
        from app.domain.books.schemas import EditionPydantic
        edition = EditionPydantic(**_valid_edition_payload(pages=value))
        assert edition.number_of_pages == value

    @pytest.mark.parametrize(
        "value, description",
        [
            ("trezentas", "string não-numérica — tipo errado"),
        ],
        ids=["string_nao_numerica"],
    )
    def test_pages_invalid_type(self, value, description):
        """Classe INVÁLIDA de number_of_pages: tipo não-inteiro."""
        from app.domain.books.schemas import EditionPydantic
        with pytest.raises(ValidationError):
            EditionPydantic(**_valid_edition_payload(pages=value))

    def test_pages_invalid_absent(self):
        """Classe INVÁLIDA de number_of_pages: campo ausente (required)."""
        from app.domain.books.schemas import EditionPydantic
        payload = _valid_edition_payload()
        del payload["pages"]
        with pytest.raises(ValidationError):
            EditionPydantic(**payload)

    # ---- language (enum Language) ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("PT-br", "Português brasileiro"),
            ("En", "Inglês"),
            ("Espanhol", "Espanhol"),
        ],
        ids=["pt_br", "ingles", "espanhol"],
    )
    def test_language_valid(self, value, description):
        """Classe VÁLIDA de language: valor pertencente ao enum Language."""
        from app.domain.books.schemas import EditionPydantic
        edition = EditionPydantic(**_valid_edition_payload(language=value))
        assert edition.language.value == value

    @pytest.mark.parametrize(
        "value, description",
        [
            ("Francês", "idioma inexistente no enum"),
            ("pt-br", "case incorreto — enums são case-sensitive"),
            ("", "string vazia"),
        ],
        ids=["fora_do_enum", "case_errado", "vazio"],
    )
    def test_language_invalid(self, value, description):
        """Classe INVÁLIDA de language: valor fora do enum Language."""
        from app.domain.books.schemas import EditionPydantic
        with pytest.raises(ValidationError):
            EditionPydantic(**_valid_edition_payload(language=value))

    # ---- cover_photo (Optional[str]) ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("https://example.com/cover.jpg", "URL de imagem"),
            (None, "None — campo é opcional"),
        ],
        ids=["url_string", "none"],
    )
    def test_cover_photo_valid(self, value, description):
        """Classe VÁLIDA de cover_photo: qualquer string ou None (é Optional)."""
        from app.domain.books.schemas import EditionPydantic
        payload = _valid_edition_payload()
        if value is None:
            payload.pop("cover_photo", None)
        else:
            payload["cover_photo"] = value
        edition = EditionPydantic(**payload)
        assert edition.cover_photo == value


# ============================================================================
# 3. TradeAnnouncementPydantic — Validação de Criação de Anúncio de Troca
# ============================================================================
#
# Critérios de particionamento por campo:
#
# edition_id (str, alias "editionId", obrigatório):
#   Válida: qualquer string não-vazia
#   Inválida: campo ausente (required)
#
# condition (Condition enum: "New", "Good", "Used", "Worn"):
#   Válida: qualquer valor pertencente ao enum
#   Inválida: valor fora do enum
#
# description (str, obrigatório):
#   Válida: qualquer string
#   Inválida: campo ausente
#
# real_photo_url (str, alias "coverUrl", obrigatório):
#   Válida: qualquer string
#   Inválida: campo ausente
#
# status (Status enum: "Available", "Reserved", "Traded", default=Available):
#   Válida: qualquer valor do enum, ou omitido (usa default)
#   Inválida: valor fora do enum
#
# cep_id (Optional[str], alias "cep"):
#   Válida: string ou None (ausente)
#   (Não possui classe inválida — é Optional e aceita qualquer string)
# ============================================================================

class TestTradeAnnouncementEquivalencePartitioning:
    """Testes de particionamento para TradeAnnouncementPydantic (announcements/schemas.py).

    Cada teste isola UM campo, mantendo os demais válidos.
    """

    # ---- edition_id (alias "editionId") ----

    def test_edition_id_valid(self):
        """Classe VÁLIDA de edition_id: string não-vazia."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        ann = TradeAnnouncementPydantic(**_valid_announcement_payload(editionId="uuid-abc-123"))
        assert ann.edition_id == "uuid-abc-123"

    def test_edition_id_invalid_absent(self):
        """Classe INVÁLIDA de edition_id: campo ausente (required)."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        payload = _valid_announcement_payload()
        del payload["editionId"]
        with pytest.raises(ValidationError):
            TradeAnnouncementPydantic(**payload)

    # ---- condition (enum Condition) ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("New", "Novo — livro sem uso"),
            ("Good", "Bom — pouco desgaste"),
            ("Used", "Usado — desgaste visível"),
            ("Worn", "Desgastado — bastante uso"),
        ],
        ids=["new", "good", "used", "worn"],
    )
    def test_condition_valid(self, value, description):
        """Classe VÁLIDA de condition: cada valor do enum Condition."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        ann = TradeAnnouncementPydantic(**_valid_announcement_payload(condition=value))
        assert ann.condition.value == value

    @pytest.mark.parametrize(
        "value, description",
        [
            ("Excellent", "valor inexistente no enum"),
            ("new", "case incorreto — enums são case-sensitive"),
            ("", "string vazia"),
        ],
        ids=["fora_do_enum", "case_errado", "vazio"],
    )
    def test_condition_invalid(self, value, description):
        """Classe INVÁLIDA de condition: valor que não pertence ao enum Condition."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        with pytest.raises(ValidationError):
            TradeAnnouncementPydantic(**_valid_announcement_payload(condition=value))

    # ---- description ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("Livro em ótimo estado, sem marcas", "descrição típica"),
            ("x", "descrição mínima — 1 char"),
        ],
        ids=["tipica", "minima"],
    )
    def test_description_valid(self, value, description):
        """Classe VÁLIDA de description: qualquer string."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        ann = TradeAnnouncementPydantic(**_valid_announcement_payload(description=value))
        assert ann.description == value

    def test_description_invalid_absent(self):
        """Classe INVÁLIDA de description: campo ausente (required)."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        payload = _valid_announcement_payload()
        del payload["description"]
        with pytest.raises(ValidationError):
            TradeAnnouncementPydantic(**payload)

    # ---- real_photo_url (alias "coverUrl") ----

    def test_cover_url_valid(self):
        """Classe VÁLIDA de real_photo_url: string com URL."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        ann = TradeAnnouncementPydantic(
            **_valid_announcement_payload(coverUrl="https://storage.example.com/photo.png")
        )
        assert ann.real_photo_url == "https://storage.example.com/photo.png"

    def test_cover_url_invalid_absent(self):
        """Classe INVÁLIDA de real_photo_url: campo ausente (required, sem default)."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        payload = _valid_announcement_payload()
        del payload["coverUrl"]
        with pytest.raises(ValidationError):
            TradeAnnouncementPydantic(**payload)

    # ---- status (enum Status, default=Available) ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("Available", "Disponível para troca"),
            ("Reserved", "Reservado — em negociação"),
            ("Traded", "Trocado — concluído"),
        ],
        ids=["available", "reserved", "traded"],
    )
    def test_status_valid_explicit(self, value, description):
        """Classe VÁLIDA de status (explícito): cada valor do enum Status."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        ann = TradeAnnouncementPydantic(**_valid_announcement_payload(status=value))
        assert ann.status.value == value

    def test_status_valid_default(self):
        """Classe VÁLIDA de status (default): quando omitido, assume 'Available'."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        payload = _valid_announcement_payload()
        payload.pop("status", None)  # garante que não foi passado
        ann = TradeAnnouncementPydantic(**payload)
        assert ann.status.value == "Available"

    @pytest.mark.parametrize(
        "value, description",
        [
            ("Sold", "valor inexistente no enum Status"),
            ("available", "case incorreto"),
        ],
        ids=["fora_do_enum", "case_errado"],
    )
    def test_status_invalid(self, value, description):
        """Classe INVÁLIDA de status: valor fora do enum Status."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        with pytest.raises(ValidationError):
            TradeAnnouncementPydantic(**_valid_announcement_payload(status=value))

    # ---- cep_id (Optional[str], alias "cep") ----

    @pytest.mark.parametrize(
        "value, description",
        [
            ("13000000", "CEP como string"),
            (None, "None — campo é opcional"),
        ],
        ids=["cep_string", "none"],
    )
    def test_cep_id_valid(self, value, description):
        """Classe VÁLIDA de cep_id: string ou None (é Optional)."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        payload = _valid_announcement_payload()
        if value is None:
            payload.pop("cep", None)
        else:
            payload["cep"] = value
        ann = TradeAnnouncementPydantic(**payload)
        assert ann.cep_id == value

    def test_cep_id_valid_absent(self):
        """Classe VÁLIDA de cep_id: quando omitido, default é None."""
        from app.domain.announcements.schemas import TradeAnnouncementPydantic
        payload = _valid_announcement_payload()
        payload.pop("cep", None)
        ann = TradeAnnouncementPydantic(**payload)
        assert ann.cep_id is None
