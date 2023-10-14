let tree;
let error;

const makeEdges = (t) => {
    if (!t.children || !t.children.length) return [];
    const edges = [];
    for (const e of t.children) {
        edges.push({ from: t._id, to: e._id });
        edges.push(...makeEdges(e));
    }
    return edges;
}

const makeNodes = (t) => {
    const nodes = [{ id: t._id, label: t.book.title, image: t.book.cover, value: t, shape: 'image' }];
    if (!t.children || !t.children.length) return nodes;
    for (const e of t.children) {
        nodes.push(...makeNodes(e));
    }
    return nodes;
}

const drawTree = (t) => {
    console.log(t);
    const treeContainer = document.getElementById('tree');
    const nodes = makeNodes(t);
    const edges = makeEdges(t);
    const data = {
        nodes,
        edges
    };

    const options = {
        interaction: {
            dragNodes: false,
            dragView: false
        },
        nodes: {
            borderWidth:0,
            size:42,
            color: {
                border: '#222',
                background: 'transparent'
            },
            font: {
                color: '#111',
                face: 'Walter Turncoat',
                size: 16,
                strokeWidth: 1,
                strokeColor: '#222'
            }
        },
        edges: {
            color: {
                color: '#CCC',
                highlight: '#A22'
            },
            width: 3,
            length: 275,
            hoverWidth: .05
        }
    };

    new vis.Network(treeContainer, data, options);
}

const getTree = async (treeId = window.location.href.split(/\//).pop()) => {
    try {
        const response = await fetch(`/api/trees/${treeId}`);
        if (response.status === 404) {
            throw Error("Tree not found :(");
        }

        tree = await response.json();
        drawTree(tree);
    } catch (e) {
        console.error(e);
    }
}

getTree();
