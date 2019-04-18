import React, { Component } from 'react';

class PfilePanel extends Component {

    state = {
        isUpdate : false,
    }
    

    render() {

        const {pfileState} = this.props;
        const {pfile} = pfileState.get('pfile');
        const {isUpdate} = this.state;

        console.log(pfileState.get('pfile').name);
//value={pfile.contents}
//<text className="form-control" value={pfileState.get('pfile').name}/>
        return (
            {if(isUpdate){
                <div className="card shadow mb-4">
                <div className="card-header py-3">
                    <div className="m-0 font-weight-bold text-darkblue">
                    {pfileState.get('pfile').name}
                    </div>
                </div>
                <div className="card-body">
                    <div>
                        {pfileState.get('pfile').contents}
                    </div>
                </div>

                <div>
                    <button type="button" className="btn btn-info btn-icon-split">
                        <span className="icon text-white-50">
                            <i className="fas fa-info-circle"></i>
                        </span>
                        <span className="text">수정 하기</span>
                    </button>
                </div>
            </div>
        }}
            
        );
    }
}
export default PfilePanel;
