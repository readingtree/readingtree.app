const { createApp, ref } = Vue;

const tree = ref(undefined);
const error = ref(undefined);

createApp({

    setup() {
        const treeId = window.location.href.split(/\//).pop();

        fetch(`/api/trees/${treeId}`)
            .then(response => {
                if (response.ok()) {
                    return response.json();
                }

                if (response.status === 404) {
                    throw Error("We couldn't find that tree :(");
                }

                throw Error("Something went wrong :(");
            })
            .then(t => tree.value = t)
            .catch(e => error.value = e.toString());

        return {
            tree,
            error
        };
    }
}).mount('#app');
