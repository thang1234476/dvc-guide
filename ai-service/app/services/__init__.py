if __name__ == "__main__":
    import json

    with open("data/clean.json", encoding="utf-8") as file:
        for procedure in json.load(file):
            if "kết hôn" in procedure["ten"].lower():
                print(procedure["ma_thu_tuc"], procedure["ten"])
