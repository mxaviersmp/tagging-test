#!/bin/bash
set -e # Sai imediatamente se um comando falhar

# --- Configuração ---
# Edite este valor se a sua branch principal tiver um nome diferente (ex: master)
MAIN_BRANCH="main"

# --- Validação ---

# 1. Verifica o argumento de entrada (patch, minor, major)
BUMP_TYPE=$1
if [[ "$BUMP_TYPE" != "patch" && "$BUMP_TYPE" != "minor" && "$BUMP_TYPE" != "major" ]]; then
  echo "❌ Erro: Tipo de incremento inválido ou ausente."
  echo "Uso: $0 [patch|minor|major]"
  exit 1
fi

# 2. Verifica se 'bump-my-version' está instalado
if ! command -v bump-my-version &> /dev/null; then
    echo "❌ Erro: 'bump-my-version' não encontrado."
    echo "Por favor, instale-o (ex: pip install bump-my-version)"
    exit 1
fi

# 3. Verifica se há alterações não salvas (git status limpo)
if ! git diff-index --quiet HEAD --; then
    echo "❌ Erro: Você tem alterações não salvas (uncommitted changes)."
    echo "Faça o commit ou 'stash' delas antes de rodar este script."
    exit 1
fi

echo "🚀 Iniciando o processo de bump de versão..."

# --- Sincronização ---

# 4. Muda para a branch principal e atualiza
echo "🔄 Sincronizando com a branch '$MAIN_BRANCH'..."
git checkout $MAIN_BRANCH
git pull origin $MAIN_BRANCH

# --- Bump da Versão ---

# 5. Pega a versão atual ANTES do bump
OLD_VERSION=$(bump-my-version show current_version)
echo "Versão anterior: $OLD_VERSION"

# 6. Roda o comando de bump (isso modifica os arquivos de versão)
# Usamos --no-commit e --no-tag para replicar a lógica da GHA
echo "📈 Incrementando versão ($BUMP_TYPE)..."
bump-my-version bump $BUMP_TYPE --no-commit --no-tag

# 7. Pega a nova versão DEPOIS do bump
NEW_VERSION=$(bump-my-version show current_version)
if [ "$OLD_VERSION" == "$NEW_VERSION" ]; then
  echo "❌ Erro: A versão não foi alterada. Verifique sua configuração do 'bump-my-version'."
  git checkout . # Desfaz as alterações nos arquivos
  exit 1
fi
echo "Nova versão: $NEW_VERSION"

# --- Operações Git ---

# 8. Cria a nova branch
BRANCH_NAME="bump/v$NEW_VERSION"
echo "🌲 Criando nova branch: $BRANCH_NAME"
git checkout -b $BRANCH_NAME

# 9. Faz o commit das alterações
COMMIT_MSG="Bump version: $OLD_VERSION -> $NEW_VERSION"
echo "📦 Fazendo commit: \"$COMMIT_MSG\""
# Usa -a para adicionar todos os arquivos rastreados que foram modificados pelo bump
git commit -am "$COMMIT_MSG"

# 10. Envia (push) a nova branch para o origin
echo "📤 Enviando branch '$BRANCH_NAME' para o origin..."
git push -u origin $BRANCH_NAME

# --- Finalização ---
echo "----------------------------------------"
echo "✅ Sucesso!"
echo "A branch '$BRANCH_NAME' foi enviada para o origin."
echo "Agora você pode ir ao GitHub para criar o Pull Request."
