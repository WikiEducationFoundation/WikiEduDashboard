import React from 'react';
import { useParams } from "react-router-dom";

const BreadCrumbs = () => {
    const params = useParams();
    const moduleName = document.getElementById('react_root').getAttribute('data-module-name');
    console.log(params)
    return (
        <>
            <ol className='breadcrumbs'>
                <li><a href="/training">{I18n.t("training.training_library")}</a></li>
                <li>
                    <a href={`/training/${params.library_id}/${params.module_id}`}>
                    {moduleName}
                    </a>
                    </li>
            </ol>
        </>
    );
}

export default BreadCrumbs;