import sys

if len(sys.argv) != 3:
    print("Правильный ввод команды : python search_in_file.py <имя_файла> <искомое_слово>")
    sys.exit(1)

filename = sys.argv[1]
search_word = sys.argv[2]

try:
    with open(filename, "r", encoding="utf-8") as file:
        found = False
        for line in file:
            if search_word in line:
                print(line.strip())
                found = True

        if not found:
            print(f"Слово '{search_word}' не найдено в файле '{filename}'.")
except FileNotFoundError:
    print(f"Файл '{filename}' не найден.")
except Exception as e:
    print(f"Произошла ошибка: {e}")
