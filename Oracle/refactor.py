import os
import re
import glob

def clean_text(text):
    # Remove emojis and weird decorative chars but keep portuguese accents and standard punctuation
    emoji_pattern = re.compile(
        u"(\ud83d[\ude00-\ude4f])|"  # emoticons
        u"(\ud83c[\udf00-\uffff])|"  # symbols & pictographs (1 of 2)
        u"(\ud83d[\u0000-\uddff])|"  # symbols & pictographs (2 of 2)
        u"(\ud83d[\ude80-\udeff])|"  # transport & map symbols
        u"(\u2600-\u26FF)|"          # misc symbols
        u"(\u2700-\u27BF)",          # dingbats
        flags=re.UNICODE)
    return emoji_pattern.sub(r'', text)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()

    filename = os.path.basename(filepath)
    content = clean_text(content)

    # 1. Extract Objective
    objective = "Laboratório prático de Oracle Database 19c."
    obj_match = re.search(r'Objetivo\s*:\s*(.*?)(?=\n\s*Autor|\n\s*\*|\n\s*$)', content, re.IGNORECASE | re.DOTALL)
    if obj_match:
        objective = obj_match.group(1).strip()
        objective = re.sub(r'\s+', ' ', objective) # collapse newlines
    
    # 2. Build New Header
    new_header = f"""/*******************************************************************************
  REPOSITÓRIO DE ESTUDOS - DBA EDUCATION LAB
  Arquivo      : {filename}
  Objetivo     : {objective}
  Autor        : Arley Ribeiro (DBA Júnior)
  Referências  : Oracle Database 19c Documentation
*******************************************************************************/
"""

    # Extract body properly
    # Match the entire top block comment /* ... */ and remove it
    body = re.sub(r'^/\*.*?\*/\s*', '', content, flags=re.DOTALL)

    # 3. Remove all INSERT statements
    # regex for INSERT INTO ...
    # Non-greedy match until ;
    body = re.sub(r'(?i)^\s*INSERT\s+INTO\s+.*?;', '', body, flags=re.MULTILINE | re.DOTALL)
    body = re.sub(r'(?i)INSERT\s+INTO\s+[^\n;]*;', '', body)

    # 4. Standardize usernames / schemas
    replacements = {
        r'\barleyribeiro2\b': 'USUARIO_TESTE2',
        r'\barleyribeiro\b': 'USUARIO_TESTE',
        r'\bfinance\b': 'TESTE',
        r'\bc##commonuser\b': 'C##USUARIO_TESTE',
        r'\bbackup_user\b': 'USUARIO_BACKUP_TESTE',
        r'\brman_cat\b': 'C##RMAN_CAT_TESTE'
    }
    for old, new in replacements.items():
        body = re.sub(old, new, body, flags=re.IGNORECASE)

    # 5. Section Headers: Transform `-- X. NOME` or `-- PARTE X: NOME` to `/* PARTE X - NOME */`
    def section_repl(match):
        text = match.group(2).strip()
        text = re.sub(r'^(PARTE\s*\d+|[0-9]+)\s*[:.-]?\s*', '', text, flags=re.IGNORECASE).strip()
        # find the number if possible
        num_match = re.search(r'PARTE\s*(\d+)|([0-9]+)', match.group(2), re.IGNORECASE)
        num = num_match.group(1) or num_match.group(2) if num_match else "X"
        return f"\n/* PARTE {num} - {text.upper()} */\n"

    body = re.sub(r'-{20,}\s*\n--\s*(.*?)\s*\n-{20,}', section_repl, body)
    
    # 6. Oracle 19c Standards
    body = re.sub(r'(?i)DBMS_SCHEDULER\.set_attribute', 'DBMS_SCHEDULER.SET_ATTRIBUTE', body)
    
    # 7. Add cleanup section if not present
    if 'CLEANUP' not in body.upper() and 'LIMPEZA' not in body.upper():
        cleanup_block = """
/* PARTE 99 - CLEANUP (ROTINA DE LIMPEZA) */
-- Conectar como SYSDBA e limpar objetos de laboratório
-- CONNECT / AS SYSDBA;
-- ALTER SESSION SET CONTAINER = ORCLPDB;
-- DROP USER USUARIO_TESTE CASCADE;
-- DROP USER TESTE CASCADE;
"""
        body += "\n" + cleanup_block

    # Reassemble
    final_content = new_header + "\n" + body.strip() + "\n"

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(final_content)
    print(f"Processed {filename}")

def main():
    sql_files = glob.glob('*.sql')
    for sql_file in sql_files:
        process_file(sql_file)

if __name__ == "__main__":
    main()
