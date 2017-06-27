import {instantiateWasmFile} from "../build/utils";

interface IMem {
    get_gU8Addr: (index: number) => number;
    get_gU8: (index: number) => number;
    get_gBdAddr: (index: number) => number;
    get_gBd: (index: number) => number;
};

async function load_IMem(filename: string): Promise<IMem> {
    try {
        debugger;

        console.log(`load_IMem: ${filename}`);

        // Allocate some WebAssembly.Memory if needed by the module
        let instanceMem: WebAssembly.Memory | null =
            new WebAssembly.Memory({initial:1});
        let instanceImports = {
            "env": { memory: instanceMem }
        };

        // Loadthe module
        let instance = await instantiateWasmFile(filename, instanceImports);

        // Define a class that implements IMem
        class Mem implements IMem {
            get_gU8Addr: (index: number) => number;
            get_gU8: (index: number) => number;
            get_gBdAddr: (index: number) => number;
            get_gBd: (index: number) => number;
        };

        // Allocate an instance of the class and point its
        // methods to the wasm module routines
        let iMem = new Mem();
        iMem.get_gU8Addr = instance.exports.get_gU8Addr;
        iMem.get_gU8 = instance.exports.get_gU8;
        iMem.get_gBdAddr = instance.exports.get_gBdAddr;
        iMem.get_gBd = instance.exports.get_gBd;

        return Promise.resolve(iMem);
    } catch (err) {
        throw err;
    }
}

function display(mem: IMem) {
    console.log("\nget_gBdAddr: val");
    for(let i = 0; i < 4; i++) {
        console.log(`${mem.get_gBdAddr(i)}:           get_gBd(${i})=${mem.get_gBd(i)}`);
    }

    console.log("get_gU8Addr: val");
    for(let i = 0; i < 4; i++) {
        console.log(`${mem.get_gU8Addr(i)}:           get_gU8(${i})=${mem.get_gU8(i)}`);
    }
}

async function main() {
    try {
        let mem: IMem = await load_IMem("out/src/mem.c.wasm");
        display(mem);

        console.log("");

        mem = await load_IMem("out/src/mem.wasm");
        display(mem);
    } catch(err) {
        console.log(`err=${err}`);
    }
}

main();
