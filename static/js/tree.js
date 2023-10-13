const { createApp, ref } = Vue;

const tree = ref(undefined);
const error = ref(undefined);

const getTree = async () => {
    try {
        const treeId = window.location.href.split(/\//).pop();
        const response = await fetch(`/api/trees/${treeId}`);
        if (response.status === 404) {
            throw Error("Tree not found :(");
        }
        tree.value = await response.json();
    } catch (e) {
        error.value = e.toString();
    }
}

createApp({
    setup() {
        getTree();

        return {
            tree,
            error
        };
    }
}).mount('#app');
